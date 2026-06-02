---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 데이터베이스 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 PostgreSQL 데이터베이스 관리 시스템만 지원합니다.

따라서 Linux 패키지 설치에서 사용할 데이터베이스 서버에는 두 가지 옵션이 있습니다:

- Linux 패키지 설치에 포함된 패키지된 PostgreSQL 서버를 사용합니다(구성 불필요, 권장).
- [외부 PostgreSQL 서버](#using-a-non-packaged-postgresql-database-management-server)를 사용합니다.

## Linux 패키지와 함께 제공되는 PostgreSQL 데이터베이스 서비스 사용 {#using-the-postgresql-database-service-shipped-with-the-linux-package}

### 재구성 및 PostgreSQL 다시 시작 {#reconfigure-and-postgresql-restarts}

Linux 패키지 설치는 일반적으로 `gitlab.rb` 파일에서 해당 서비스의 구성 설정을 변경한 경우 재구성 시 모든 서비스를 다시 시작합니다. PostgreSQL은 일부 설정이 다시 로드(HUP)로 적용되는 반면 다른 설정은 PostgreSQL을 다시 시작해야 한다는 점에서 고유합니다. 관리자는 PostgreSQL을 다시 시작할 정확한 시간에 대해 더 많은 제어를 원하므로, Linux 패키지 설치는 재구성 시 PostgreSQL을 다시 로드하도록 구성되며 다시 시작하지 않습니다. 이는 PostgreSQL 다시 시작이 필요한 PostgreSQL 설정을 수정하는 경우 재구성 후 PostgreSQL을 수동으로 다시 시작해야 함을 의미합니다.

[GitLab 구성 템플릿](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)에서는 어떤 PostgreSQL 설정이 다시 시작이 필요하고 어떤 설정이 다시 로드만 필요한지를 확인합니다. 데이터베이스에 대해 쿼리를 실행하여 특정 설정이 다시 시작이 필요한지를 확인할 수도 있습니다. `sudo gitlab-psql`로 데이터베이스 콘솔을 시작한 후 다음 쿼리에서 `<setting name>`를 변경하고 있는 설정으로 바꿉니다:

```sql
SELECT name,setting FROM pg_settings WHERE context = 'postmaster' AND name = '<setting name>';
```

설정을 변경하려면 다시 시작이 필요하면 쿼리가 실행 중인 PostgreSQL 인스턴스에서 설정의 이름과 현재 값을 반환합니다.

#### PostgreSQL 버전 변경 시 자동 다시 시작 {#automatic-restart-when-the-postgresql-version-changes}

기본적으로 Linux 패키지 설치는 [업스트림 문서](https://www.postgresql.org/docs/17/upgrading.html)에서 권장하는 기본 버전 변경 시 PostgreSQL을 자동으로 다시 시작합니다. 이 동작은 `auto_restart_on_version_change` 설정을 사용하여 제어할 수 있으며 `postgresql` 및 `geo-postgresql`에서 사용할 수 있습니다.

PostgreSQL 버전 변경 시 자동 다시 시작을 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 줄을 추가합니다:

   ```ruby
   # For PostgreSQL/Patroni
   postgresql['auto_restart_on_version_change'] = false

   # For Geo PostgreSQL
   geo_postgresql['auto_restart_on_version_change'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 기본 버전 변경 시 PostgreSQL을 다시 시작하는 것이 매우 좋습니다. [필요한 라이브러리 로드와 관련된 오류](#could-not-load-library-plpgsqlso)를 피하려면.

### SSL 구성 {#configuring-ssl}

Linux 패키지 설치는 자동으로 PostgreSQL 서버에서 SSL을 활성화하지만 기본적으로 암호화된 연결과 암호화되지 않은 연결을 모두 수락합니다. SSL을 강제하려면 `hostssl` 구성을 `pg_hba.conf`에서 사용해야 합니다. 자세한 내용은 [`pg_hba.conf` 문서](https://www.postgresql.org/docs/17/auth-pg-hba-conf.html)를 참조하세요.

SSL 지원은 다음 파일에 따라 달라집니다:

- 데이터베이스의 공개 SSL 인증서(`server.crt`).
- SSL 인증서에 대한 해당 개인 키(`server.key`).
- 서버의 인증서를 검증하는 루트 인증서 번들(`root.crt`). 기본적으로 Linux 패키지 설치는 `/opt/gitlab/embedded/ssl/certs/cacert.pem`에 포함된 임베디드 인증서 번들을 사용합니다. 이는 자체 서명된 인증서에는 필요하지 않습니다.

Linux 패키지 설치에서 10년 자체 서명된 인증서 및 개인 키를 생성하여 사용합니다. CA 서명 인증서를 사용하거나 자신의 자체 서명 인증서로 바꾸려면 다음 단계를 따릅니다.

이러한 파일의 위치는 구성 가능하지만 개인 키는 `gitlab-psql` 사용자가 읽을 수 있어야 합니다. Linux 패키지 설치는 파일의 권한을 관리하지만 경로가 사용자 지정된 경우 `gitlab-psql`가 파일이 배치된 디렉토리에 액세스할 수 있는지 확인해야 합니다.

자세한 내용은 [PostgreSQL 문서](https://www.postgresql.org/docs/17/ssl-tcp.html)를 참조하세요.

`server.crt` 및 `server.key`가 GitLab에 액세스하는 데 사용되는 기본 SSL 인증서와 다를 수 있습니다. 예를 들어 데이터베이스의 외부 호스트 이름이 `database.example.com`이고 외부 GitLab 호스트 이름이 `gitlab.example.com`라고 가정합니다. `*.example.com` 용 와일드카드 인증서 또는 두 개의 서로 다른 SSL 인증서가 필요합니다.

`ssl_cert_file`, `ssl_key_file` 및 `ssl_ca_file` 파일은 PostgreSQL이 인증서, 키 및 번들을 찾을 수 있는 위치를 파일 시스템에 지시합니다. 이러한 변경 사항은 `postgresql.conf`에 적용됩니다. `internal_certificate` 및 `internal_key` 지시문은 이러한 파일의 내용을 채우는 데 사용됩니다. 내용을 직접 추가하거나 다음 예시에서처럼 파일에서 로드할 수 있습니다.

이러한 파일이 있으면 SSL을 활성화합니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   postgresql['ssl_cert_file'] = '/custom/path/to/server.crt'
   postgresql['ssl_key_file'] = '/custom/path/to/server.key'
   postgresql['ssl_ca_file'] = '/custom/path/to/bundle.pem'
   postgresql['internal_certificate'] = File.read('/custom/path/to/server.crt')
   postgresql['internal_key'] = File.read('/custom/path/to/server.key')
   ```

   상대 경로는 PostgreSQL 데이터 디렉토리(`/var/opt/gitlab/postgresql/data` 기본값)에 기초합니다.

1. [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)하여 구성 변경사항을 적용합니다.
1. 변경 사항이 적용되도록 PostgreSQL을 다시 시작합니다:

   ```shell
   gitlab-ctl restart postgresql
   ```

   PostgreSQL을 시작하지 못하면 로그를 확인합니다(예: `/var/log/gitlab/postgresql/current`) 자세한 내용을 확인하세요.

#### SSL 필요 {#require-ssl}

1. `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)하여 구성 변경사항을 적용합니다.

#### SSL 비활성화 {#disabling-ssl}

1. `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   postgresql['ssl'] = 'off'
   ```

1. [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)하여 구성 변경사항을 적용합니다.
1. 변경 사항이 적용되도록 PostgreSQL을 다시 시작합니다:

   ```shell
   gitlab-ctl restart postgresql
   ```

   PostgreSQL을 시작하지 못하면 로그를 확인합니다(예: `/var/log/gitlab/postgresql/current`) 자세한 내용을 확인하세요.

#### SSL이 사용되고 있는지 확인 {#verifying-that-ssl-is-being-used}

클라이언트가 SSL을 사용하고 있는지 확인하려면 다음을 실행할 수 있습니다:

```shell
sudo gitlab-rails dbconsole --database main
```

시작 시 다음과 같은 배너가 표시되어야 합니다:

```plaintext
psql (13.14)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: on)
Type "help" for help.
```

클라이언트가 SSL을 사용하고 있는지 확인하려면 이 SQL 쿼리를 실행합니다:

```sql
SELECT * FROM pg_stat_ssl;
```

예를 들어:

```plaintext
gitlabhq_production=> select * from pg_stat_ssl;
 pid  | ssl | version |         cipher         | bits | compression |  clientdn
------+-----+---------+------------------------+------+-------------+------------
  384 | f   |         |                        |      |             |
  386 | f   |         |                        |      |             |
  998 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
  933 | f   |         |                        |      |             |
 1003 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1016 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1022 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1211 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1214 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1213 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1215 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1252 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           |
 1280 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
  382 | f   |         |                        |      |             |
  381 | f   |         |                        |      |             |
  383 | f   |         |                        |      |             |
(16 rows)
```

1. `t` 열 아래에 나열된 행은 `ssl` 활성화됩니다.
1. `clientdn`에 값이 있는 행은 `cert` 인증 방법을 사용 중입니다.

#### SSL 클라이언트 인증 구성 {#configure-ssl-client-authentication}

클라이언트 SSL 인증서를 사용하여 데이터베이스 서버에 인증할 수 있습니다. 인증서 생성은 `omnibus-gitlab`의 범위를 벗어납니다. 하지만 기존 SSL 인증서 관리 솔루션이 있는 사용자는 이를 사용할 수 있습니다.

##### 데이터베이스 서버 구성 {#configure-the-database-server}

1. 서버에 대한 인증서 및 키를 생성하고 공통 이름이 서버의 DNS 이름과 같아야 합니다.
1. 서버 인증서, 키 및 CA 파일을 PostgreSQL 서버로 복사하고 권한이 올바른지 확인합니다.
   1. 인증서는 데이터베이스 사용자(기본값: `gitlab-psql`)가 소유해야 합니다.
   1. 키 파일은 데이터베이스 사용자가 소유해야 하며 권한은 `0400`이어야 합니다.
   1. CA 파일은 데이터베이스 사용자가 소유해야 하며 권한은 `0400`이어야 합니다.

   > [!note]
   > `server.crt` 또는 `server.key` 파일 이름을 이 파일에 사용하지 마세요. 이러한 파일 이름은 `omnibus-gitlab`의 내부 사용을 위해 예약되어 있습니다.

1. `gitlab.rb`에서 다음이 설정되어 있는지 확인합니다:

   ```ruby
   postgresql['ssl_cert_file'] = 'PATH_TO_CERTIFICATE'
   postgresql['ssl_key_file'] = 'PATH_TO_KEY_FILE'
   postgresql['ssl_ca_file'] = 'PATH_TO_CA_FILE'
   postgresql['listen_address'] = 'IP_ADDRESS'
   postgresql['cert_auth_addresses'] = {
     'IP_ADDRESS' => {
       'database' => 'gitlabhq_production',
       'user' => 'gitlab'
     }
   }
   ```

   클라이언트가 데이터베이스에 연결하는 데 사용할 서버의 IP 주소로 `listen_address`을 설정합니다. `cert_auth_addresses`에 데이터베이스에 연결할 수 있는 IP 주소와 데이터베이스 및 사용자 목록이 포함되어 있는지 확인합니다. IP 주소 범위를 포함하도록 `cert_auth_addresses`에 대한 키를 지정할 때 CIDR 표기법을 사용할 수 있습니다.

1. `gitlab-ctl reconfigure`을 실행한 다음 `gitlab-ctl restart postgresql`를 실행하여 새 설정을 적용합니다.

#### Rails 클라이언트 구성 {#configure-the-rails-client}

Rails 클라이언트가 서버에 연결하려면 `commonName`이 `gitlab`로 설정된 인증서 및 키가 필요하며, 이는 데이터베이스 서버의 `ssl_ca_file`에 지정된 CA 파일에서 신뢰하는 인증 기관에 의해 서명됩니다.

1. `gitlab.rb`을 구성합니다.

   ```ruby
   gitlab_rails['db_host'] = 'IP_ADDRESS_OR_HOSTNAME_OF_DATABASE_SERVER'
   gitlab_rails['db_sslcert'] = 'PATH_TO_CERTIFICATE_FILE'
   gitlab_rails['db_sslkey'] = 'PATH_TO_KEY_FILE'
   gitlab_rails['db_rootcert'] = 'PATH_TO_CA_FILE'
   ```

1. Rails 클라이언트가 새 설정을 사용하도록 `gitlab-ctl reconfigure`을 실행합니다.
1. [SSL이 사용되고 있는지 확인](#verifying-that-ssl-is-being-used)에서 단계를 따라 인증이 작동하는지 확인합니다.

### 패키지된 PostgreSQL 서버를 TCP/IP에서 수신하도록 구성 {#configure-packaged-postgresql-server-to-listen-on-tcpip}

패키지된 PostgreSQL 서버는 TCP/IP 연결을 수신하도록 구성할 수 있지만 일부 중요하지 않은 스크립트가 UNIX 소켓을 기대하고 오작동할 수 있습니다.

데이터베이스 서비스에 TCP/IP를 사용하도록 구성하려면 `postgresql` 및 `gitlab_rails` 섹션 모두를 `gitlab.rb`에서 변경해야 합니다.

#### PostgreSQL 블록 구성 {#configure-postgresql-block}

`postgresql` 블록에서 다음 설정이 영향을 받습니다:

- `listen_address`: PostgreSQL이 수신할 주소를 제어합니다.
- `port`: PostgreSQL이 수신하는 포트를 제어합니다. 기본값은 `5432`입니다.
- `md5_auth_cidr_addresses`: 비밀번호로 인증한 후 서버에 연결할 수 있는 CIDR 주소 블록 목록입니다.
- `trust_auth_cidr_addresses`: 인증 없이 서버에 연결할 수 있는 CIDR 주소 블록 목록입니다. 이 설정은 GitLab Rails 또는 Sidekiq과 같이 연결이 필요한 노드에서만 연결을 허용하도록 설정해야 합니다. 여기에는 동일한 노드에 배포되거나 Postgres Exporter(`127.0.0.1/32`) 같은 구성 요소에서 로컬 연결이 포함됩니다.
- `sql_user`: MD5 인증을 위해 예상되는 사용자 이름을 제어합니다. 이는 `gitlab`로 기본값이지정되며 필수 설정이 아닙니다.
- `sql_user_password`: PostgreSQL이 MD5 인증을 수락할 비밀번호를 설정합니다.

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432
   postgresql['md5_auth_cidr_addresses'] = %w()
   postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/24)
   postgresql['sql_user'] = "gitlab"

   ##! SQL_USER_PASSWORD_HASH can be generated using the command `gitlab-ctl pg-password-md5 'gitlab'`,
   ##! where 'gitlab' (single-quoted to avoid shell interpolation) is the name of the SQL user that connects to GitLab.
   ##! You will be prompted for a password which other clients will use to authenticate with database, such as `securesqlpassword` in the below section.
   postgresql['sql_user_password'] = "SQL_USER_PASSWORD_HASH"

   # force ssl on all connections defined in trust_auth_cidr_addresses and md5_auth_cidr_addresses
   postgresql['hostssl'] = true
   ```

1. GitLab을 재구성하고 PostgreSQL을 다시 시작합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

네트워크를 통해 연결할 모든 클라이언트 또는 GitLab 서비스는 PostgreSQL 서버에 연결할 때 `sql_user`의 값을 사용자 이름으로 제공하고 구성에 제공된 비밀번호를 제공해야 합니다. 또한 `md5_auth_cidr_addresses`에 제공된 네트워크 블록 내에 있어야 합니다.

#### GitLab Rails 블록 구성 {#configure-gitlab-rails-block}

`gitlab-rails` 애플리케이션을 네트워크를 통해 PostgreSQL 데이터베이스에 연결하도록 구성하려면 여러 설정을 구성해야 합니다:

- `db_host`: 데이터베이스 서버의 IP 주소로 설정해야 합니다. 이것이 PostgreSQL 서비스와 동일한 인스턴스에 있으면 `127.0.0.1`이 될 수 있으며 비밀번호 인증이 필요하지 않습니다.
- `db_port`: PostgreSQL 서버에 연결할 포트를 설정하며 `db_host`가 설정된 경우 설정해야 합니다.
- `db_username`: PostgreSQL에 연결할 사용자 이름을 구성합니다. 이는 `gitlab`로 기본값이 지정됩니다.
- `db_password`: TCP/IP를 통해 PostgreSQL에 연결하고 위의 설정에서 `postgresql['md5_auth_cidr_addresses']` 블록의 인스턴스에서 제공해야 합니다. `127.0.0.1`에 연결하고 `postgresql['trust_auth_cidr_addresses']`를 포함하도록 구성한 경우에는 필요하지 않습니다.

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = "gitlab"
   gitlab_rails['db_password'] = "securesqlpassword"
   ```

1. GitLab을 재구성하고 PostgreSQL을 다시 시작합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

#### 서비스 적용 및 다시 시작 {#apply-and-restart-services}

위의 변경 사항을 적용한 후 관리자는 `gitlab-ctl reconfigure`을 실행해야 합니다. TCP에서 수신 대기하지 않는 서비스와 관련된 이슈가 발생하면 `gitlab-ctl restart postgresql`으로 서비스를 직접 다시 시작해 봅니다.

Linux 패키지의 일부 포함된 스크립트(예: `gitlab-psql`)는 PostgreSQL 연결을 UNIX 소켓을 통해 처리하기를 기대하며 제대로 작동하지 않을 수 있습니다. UNIX 소켓을 비활성화하지 않고 TCP/IP를 활성화할 수 있습니다.

다른 클라이언트에서 액세스를 테스트하려면 다음을 실행할 수 있습니다:

```shell
sudo gitlab-rails dbconsole --database main
```

### PostgreSQL WAL(Write Ahead Log) 아카이빙 활성화 {#enabling-postgresql-wal-write-ahead-log-archiving}

기본적으로 패키지된 PostgreSQL의 WAL 아카이빙은 활성화되지 않습니다. WAL 아카이빙을 활성화할 때 다음을 고려합니다:

- WAL 레벨은 'replica' 또는 그 이상이어야 합니다(9.6+ 옵션은 `minimal`, `replica` 또는 `logical`).
- WAL 레벨을 높이면 일반 작업에서 소비되는 저장소 양이 증가합니다.

WAL 아카이빙을 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Replication settings
   postgresql['sql_replication_user'] = "gitlab_replicator"
   postgresql['wal_level'] = "replica"
       ...
       ...
   # Backup/Archive settings
   postgresql['archive_mode'] = "on"
   postgresql['archive_command'] = "/your/wal/archiver/here"
   postgresql['archive_timeout'] = "60"
   ```

1. [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)합니다. 변경 사항이 적용되도록 합니다. 이로 인해 데이터베이스가 다시 시작됩니다.

### PostgreSQL 데이터를 다른 디렉토리에 저장 {#store-postgresql-data-in-a-different-directory}

기본적으로 모든 것이 `/var/opt/gitlab/postgresql` 아래에 저장되며 `postgresql['dir']` 속성으로 제어됩니다.

이는 다음으로 구성됩니다:

- 데이터베이스 소켓은 `/var/opt/gitlab/postgresql/.s.PGSQL.5432`입니다. 이는 `postgresql['unix_socket_directory']`로 제어됩니다.
- `gitlab-psql` 시스템 사용자는 이것으로 설정된 `HOME` 디렉토리를 가집니다. 이는 `postgresql['home']`로 제어됩니다.
- 실제 데이터는 `/var/opt/gitlab/postgresql/data`에 저장됩니다.

PostgreSQL 데이터의 위치를 변경하려면

기존 데이터베이스가 있으면 먼저 데이터를 새 위치로 이동해야 합니다.

> [!warning]
> 이는 침입적인 작업입니다. 기존 설치에서 가동 중지 시간 없이 수행할 수 없습니다.

1. 이것이 기존 설치이면 GitLab을 중지합니다. `gitlab-ctl stop`
1. `postgresql['dir']`을 원하는 위치로 업데이트합니다.
1. `gitlab-ctl reconfigure`을(를) 실행합니다.
1. GitLab을 시작합니다. `gitlab-ctl start`

### 패키지된 PostgreSQL 서버 업그레이드 {#upgrade-packaged-postgresql-server}

GitLab에서 관리하는 Patroni 클러스터(PostgreSQL HA)가 있는 경우 대신 다음 문서를 사용합니다:

- [Patroni 클러스터에서 PostgreSQL 주 버전 업그레이드](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster)
- [Patroni 클러스터에서 PostgreSQL 거의 무중단 업그레이드](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster)

Linux 패키지는 `gitlab-ctl pg-upgrade` 명령을 제공하여 패키지된 PostgreSQL 서버를 이후 버전으로 업데이트합니다(패키지에 포함된 경우). 이는 패키지 업그레이드 중에 PostgreSQL을 [기본 제공 버전](https://docs.gitlab.com/administration/package_information/postgresql_versions/) 으로 업데이트하지만 구체적으로 [옵트 아웃](#opt-out-of-automatic-postgresql-upgrades)하지 않는 경우입니다.

GitLab을 최신 버전으로 업그레이드하기 전에 Linux 패키지의 [버전별 변경사항](https://docs.gitlab.com/update/#version-specific-upgrading-instructions)을 참조하여 다음을 확인합니다:

- 데이터베이스 버전이 변경되었을 때입니다.
- 업그레이드가 필요할 때입니다.

명령을 실행하기 전에 이 섹션을 완전히 읽는 것이 중요합니다. 단일 노드 설치의 경우 이 업그레이드는 업그레이드를 수행하는 동안 데이터베이스가 다운되어야 하므로 가동 중지 시간이 필요합니다. 시간 길이는 데이터베이스의 크기에 따라 달라집니다.

> [!note]
> 업그레이드 중에 이슈가 발생하면 [`omnibus-gitlab` 이슈 추적기](https://gitlab.com/gitlab-org/omnibus-gitlab)에서 전체 설명이 있는 이슈를 제출합니다.

PostgreSQL 버전을 업그레이드하려면 다음을 확인합니다:

- PostgreSQL의 현재 버전을 지원하는 최신 버전의 GitLab을 실행 중입니다.
- 최근에 업그레이드했다면 진행하기 전에 `sudo gitlab-ctl reconfigure`을 성공적으로 실행했습니다.
- 데이터베이스의 두 개 복사본을 위한 충분한 디스크 공간이 있습니다. _충분한 여유 공간이 있지 않으면 업그레이드를 시도하지 마세요._

  - `sudo du -sh /var/opt/gitlab/postgresql/data`을 사용하여 데이터베이스 크기를 확인합니다(또는 데이터베이스 경로를 업데이트합니다).
  - `sudo df -h`을 사용하여 사용 가능한 공간을 확인합니다. 데이터베이스가 있는 파티션에 충분한 공간이 없으면 `--tmp-dir $DIR` 인수를 명령에 전달합니다. 업그레이드 작업에는 사용 가능한 디스크 공간 확인이 포함되어 있으며 요구사항을 충족하지 않으면 업그레이드를 중단합니다.
    - 사용자 지정 임시 디렉토리를 사용하는 경우 올바른 사용자 및 그룹 소유권이 있는지 확인합니다. `ls -la /var/opt/gitlab/postgresql/data`을 실행하여 소유자 및 그룹을 확인한 다음 `sudo chown <user>:<group> $DIR`로 임시 디렉토리에 동일한 소유권을 설정합니다. 기본 설치의 경우 소유자는 `gitlab-psql`이며 명령은 `sudo chown gitlab-psql:gitlab-psql $DIR`입니다.

위의 체크리스트가 충족되었음을 확인한 후 업그레이드를 진행할 수 있습니다:

```shell
sudo gitlab-ctl pg-upgrade
```

특정 PostgreSQL 버전으로 업그레이드하려면 `-V` 플래그를 사용하여 버전을 추가합니다. 예를 들어 PostgreSQL 17로 업그레이드하려면:

```shell
sudo gitlab-ctl pg-upgrade -V 17
```

> [!note]
> `pg-upgrade`는 인수를 사용할 수 있습니다(예: 기본 명령 실행에 대한 타임아웃을 설정할 수 있음 `--timeout=1d2h3m4s5ms`). `gitlab-ctl pg-upgrade -h`를 실행하여 전체 목록을 확인합니다.

`gitlab-ctl pg-upgrade`은 다음 단계를 수행합니다:

1. 데이터베이스가 알려진 양호한 상태인지 확인합니다.
1. 충분한 여유 디스크 공간이 있는지 확인하고 그렇지 않으면 중단합니다. `--skip-disk-check` 플래그를 추가하여 이를 건너뛸 수 있습니다.
1. 기존 데이터베이스 및 불필요한 서비스를 종료하고 GitLab 배포 페이지를 활성화합니다.
1. `/opt/gitlab/embedded/bin/` 의 심볼릭 링크를 변경하여 PostgreSQL이 최신 버전의 데이터베이스를 가리키도록 합니다.
1. 기존 데이터베이스와 로케일이 일치하는 새 빈 데이터베이스를 포함하는 새 디렉토리를 생성합니다.
1. `pg_upgrade` 도구를 사용하여 기존 데이터베이스에서 새 데이터베이스로 데이터를 복사합니다.
1. 기존 데이터베이스를 옮깁니다.
1. 새 데이터베이스를 예상 위치로 이동합니다.
1. `sudo gitlab-ctl reconfigure`을 호출하여 필수 구성 변경 사항을 수행하고 새 데이터베이스 서버를 시작합니다.
1. `ANALYZE`을 실행하여 데이터베이스 통계를 생성합니다.
1. 남은 서비스를 시작하고 배포 페이지를 제거합니다.
1. 이 프로세스 중에 오류가 감지되면 데이터베이스의 이전 버전으로 되돌립니다.

업그레이드가 완료되면 모든 것이 예상대로 작동하는지 확인합니다.

`ANALYZE` 단계를 실행하는 동안 출력에 오류가 있었다면 업그레이드는 계속 작동하지만 데이터베이스 통계가 생성될 때까지 데이터베이스 성능이 저하됩니다. `gitlab-psql`을 사용하여 `ANALYZE`을 수동으로 실행해야 하는지 확인합니다:

```shell
sudo gitlab-psql -c "SELECT relname, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL AND last_autoanalyze IS NULL;"
```

위의 쿼리가 행을 반환한 경우 `ANALYZE`을 수동으로 실행할 수 있습니다:

```shell
sudo gitlab-psql -c 'SET statement_timeout = 0; ANALYZE VERBOSE;'
```

`ANALYZE` 명령의 실행 시간은 데이터베이스 크기에 따라 크게 달라질 수 있습니다. 이 작업의 진행 상황을 모니터링하려면 다른 콘솔 세션에서 다음 쿼리를 주기적으로 실행할 수 있습니다. `tables_remaining` 열은 `0`에 도달해야 합니다:

```shell
sudo gitlab-psql -c "
SELECT
    COUNT(*) AS total_tables,
    SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
FROM pg_stat_user_tables;
"
```

업그레이드가 완료되고 GitLab 인스턴스가 올바르게 실행 중임을 확인한 후 이전 데이터베이스 파일을 정리할 수 있습니다:

```shell
sudo rm -rf /var/opt/gitlab/postgresql/data.<old_version>
sudo rm -f /var/opt/gitlab/postgresql-version.old
```

[Linux 패키지와 함께 제공되는 PostgreSQL 버전](https://docs.gitlab.com/administration/package_information/postgresql_versions/)에서 다양한 GitLab 버전과 함께 제공되는 PostgreSQL 버전의 세부 정보를 찾을 수 있습니다.

#### 자동 PostgreSQL 업그레이드 옵트 아웃 {#opt-out-of-automatic-postgresql-upgrades}

GitLab 패키지 업그레이드 중에 자동 PostgreSQL 업그레이드를 옵트 아웃하려면 다음을 실행합니다:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

Docker 이미지를 사용하는 경우 `GITLAB_SKIP_PG_UPGRADE` 환경 변수를 `true`로 설정하여 자동 업그레이드를 비활성화할 수 있습니다.

### 패키지된 PostgreSQL 서버를 이전 버전으로 되돌리기 {#revert-packaged-postgresql-server-to-the-previous-version}

> [!warning]
> 이 작업은 현재 데이터베이스(데이터 포함)를 마지막 업그레이드 전 상태로 되돌립니다. 패키지된 PostgreSQL 데이터베이스를 되돌리기 전에 백업을 생성해야 합니다.

이전 버전의 Linux 패키지는 여러 버전의 PostgreSQL을 번들로 묶습니다. 이러한 버전 중 하나를 사용하는 경우 `gitlab-ctl revert-pg-upgrade` 명령을 사용하여 Linux 패키지에서 지원하는 이전 PostgreSQL 버전으로 되돌릴 수 있습니다. 이 명령은 또한 대상 버전을 지정하기 위한 `-V` 플래그를 지원합니다. 예를 들어 PostgreSQL 버전 14로 되돌리려면:

```shell
gitlab-ctl revert-pg-upgrade -V 14
```

대상 버전을 지정하지 않으면 명령은 `/var/opt/gitlab/postgresql-version.old`에서 버전을 사용합니다(사용 가능한 경우). 그렇지 않으면 GitLab과 함께 제공되는 기본 버전으로 돌아갑니다.

PostgreSQL 버전 하나만 제공하는 Linux 패키지 버전을 사용하는 경우 PostgreSQL 버전을 되돌릴 수 없습니다. 이러한 Linux 패키지 버전의 경우 이전 버전의 PostgreSQL을 사용하려면 GitLab을 이전 버전으로 롤백해야 합니다.

### 여러 데이터베이스 연결 구성 {#configuring-multiple-database-connections}

{{< history >}}

- `gitlab:db:decomposition:connection_status` Rake 작업은 GitLab 15.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111927)되었습니다.

{{< /history >}}

GitLab 16.0에서 GitLab은 기본적으로 동일한 PostgreSQL 데이터베이스를 가리키는 두 개의 데이터베이스 연결을 사용합니다.

GitLab 16.0으로 업그레이드하기 전에 PostgreSQL `max_connections` 설정이 50% 이상의 사용 가능한 연결이 사용되지 않는 것으로 표시될 정도로 충분히 높은지 확인합니다. 예를 들어 `max_connections`이 100으로 설정되고 75개의 연결이 사용 중인 경우 업그레이드 후 사용 중인 연결이 150으로 두 배가 되므로 업그레이드 전에 `max_connections`을 최소 150으로 증가시켜야 합니다.

다음 Rake 작업을 실행하여 이를 확인할 수 있습니다:

```shell
sudo gitlab-rake gitlab:db:decomposition:connection_status
```

작업이 `max_connections`이 충분히 높다고 표시하면 업그레이드를 진행할 수 있습니다.

## 패키지되지 않은 PostgreSQL 데이터베이스 관리 서버 사용 {#using-a-non-packaged-postgresql-database-management-server}

기본적으로 GitLab은 Linux 패키지에 포함된 PostgreSQL 서버를 사용하도록 구성됩니다. 또한 PostgreSQL의 외부 인스턴스를 사용하도록 재구성할 수 있습니다.

> [!warning]
> 패키지되지 않은 PostgreSQL 서버를 사용하는 경우 PostgreSQL이 [데이터베이스 요구사항](https://docs.gitlab.com/install/requirements/#postgresql)에 따라 설정되었는지 확인해야 합니다.

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = 'USERNAME'
   gitlab_rails['db_password'] = 'PASSWORD'
   ```

   이 줄의 시작 부분에서 `#` 주석 문자를 제거하는 것을 잊지 마세요.

   다음을 참고하세요:

   - `/etc/gitlab/gitlab.rb`은 일반 텍스트 비밀번호를 포함하므로 `0600` 파일 권한이 있어야 합니다.
   - PostgreSQL은 [여러 주소](https://www.postgresql.org/docs/11/runtime-config-connection.html)에서 수신 대기할 수 있습니다.

     `gitlab_rails['db_host']`에서 여러 주소를 쉼표로 구분하여 사용하는 경우 목록의 첫 번째 주소가 연결에 사용됩니다.

1. [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)합니다. 변경 사항이 적용되도록 합니다.
1. [데이터베이스 시드](#seed-the-database-fresh-installs-only)합니다.
1. 선택 사항입니다. [컨테이너 레지스트리 메타데이터 데이터베이스 활성화](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)합니다.

### 패키지되지 않은 PostgreSQL에 대한 UNIX 소켓 구성 {#unix-socket-configuration-for-non-packaged-postgresql}

GitLab과 함께 번들로 제공되는 것 대신 GitLab과 동일한 시스템에 설치된 시스템의 PostgreSQL 서버를 사용하려면 UNIX 소켓을 사용하여 이를 수행할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   # The path where the socket lives
   gitlab_rails['db_host'] = '/var/run/postgresql/'
   ```

1. GitLab을 재구성합니다. 변경 사항이 적용되도록 합니다:

   ```ruby
   sudo gitlab-ctl-reconfigure
   ```

### SSL 구성 {#configuring-ssl-1}

#### SSL 필요 {#require-ssl-1}

1. `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)하여 구성 변경사항을 적용합니다.

#### CA 번들에 대한 SSL 필수 및 서버 인증서 확인 {#require-ssl-and-verify-server-certificate-against-ca-bundle}

PostgreSQL은 SSL을 필요로 하고 스푸핑을 방지하기 위해 CA 번들에 대한 서버 인증서를 확인하도록 구성할 수 있습니다. `gitlab_rails['db_sslrootcert']`에 지정된 CA 번들은 루트 및 중간 인증서를 모두 포함해야 합니다.

1. `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   gitlab_rails['db_sslmode'] = "verify-full"
   gitlab_rails['db_sslrootcert'] = "<full_path_to_your_ca-bundle.pem>"
   ```

   PostgreSQL 서버에 Amazon RDS를 사용하는 경우 [결합된 CA 번들](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem)을 다운로드하여 `gitlab_rails['db_sslrootcert']`에 사용해야 합니다. 이에 대한 자세한 내용은 AWS의 [SSL/TLS를 사용하여 DB 인스턴스로의 연결 암호화](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html) 문서에서 찾을 수 있습니다.

1. [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)하여 구성 변경사항을 적용합니다.

### 패키지되지 않은 PostgreSQL 데이터베이스 백업 및 복원 {#backup-and-restore-a-non-packaged-postgresql-database}

[백업](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command) 및 [복원](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations) 명령을 사용할 때 GitLab은 패키지된 `pg_dump` 명령을 사용하여 데이터베이스 백업 파일을 생성하고 패키지된 `psql` 명령을 사용하여 백업을 복원하려고 합니다. 이는 올바른 버전인 경우에만 작동합니다. 패키지된 `pg_dump` 및 `psql`의 버전을 확인합니다:

```shell
/opt/gitlab/embedded/bin/pg_dump --version
/opt/gitlab/embedded/bin/psql --version
```

이러한 버전이 패키지되지 않은 외부 PostgreSQL과 다르면 [백업 명령](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)을 실행하려고 할 때 다음 오류 출력을 만날 수 있습니다.

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 12.6
pg_dump: error: aborting because of server version mismatch
```

이 예에서 오류는 [기본 제공 PostgreSQL 버전](https://docs.gitlab.com/administration/package_information/postgresql_versions/) 12.6 대신 PostgreSQL 버전 13.3을 사용할 때 GitLab 14.1에서 발생합니다.

이 경우 데이터베이스 버전과 일치하는 도구를 설치한 다음 아래 단계를 따라야 합니다. PostgreSQL 클라이언트 도구를 설치하는 방법은 여러 가지입니다. <https://www.postgresql.org/download/>을 참조하여 옵션을 확인합니다.

올바른 `psql` 및 `pg_dump` 도구를 시스템에서 사용할 수 있으면 다음 단계를 따릅니다. 새 도구를 설치한 위치로 올바른 경로를 사용합니다:

1. 패키지되지 않은 버전에 대한 심볼릭 링크를 추가합니다:

   ```shell
   ln -s /path/to/new/pg_dump /path/to/new/psql /opt/gitlab/bin/
   ```

1. 버전을 확인합니다:

   ```shell
   /opt/gitlab/bin/pg_dump --version
   /opt/gitlab/bin/psql --version
   ```

   이제 패키지되지 않은 외부 PostgreSQL과 동일해야 합니다.

이 작업이 완료되면 [백업](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command) 및 [복원](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations) 명령을 모두 실행하여 백업 및 복원 작업이 올바른 실행 파일을 사용하고 있는지 확인합니다.

### 패키지되지 않은 PostgreSQL 데이터베이스 업그레이드 {#upgrade-a-non-packaged-postgresql-database}

데이터베이스에 연결된 모든 프로세스(Puma, Sidekiq)를 중지한 후 외부 데이터베이스를 업그레이드할 수 있습니다:

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
```

업그레이드를 진행하기 전에 다음을 참고합니다:

- GitLab 릴리스와 PostgreSQL 버전 간의 호환성을 확인합니다:
  - PostgreSQL에 대한 [최소 버전](https://docs.gitlab.com/install/requirements/#postgresql)이 필요한 GitLab 버전을 알아봅니다.
  - PostgreSQL 버전에 대한 중대한 변경사항을 확인합니다. [Linux 패키지와 함께 제공](https://docs.gitlab.com/administration/package_information/postgresql_versions/)됩니다:  Linux 패키지는 함께 제공되는 PostgreSQL의 주 릴리스와의 호환성에 대해 테스트됩니다.
- GitLab 백업 또는 복원을 사용할 때 GitLab의 동일한 버전을 유지해야 합니다. 나중에 GitLab 버전으로 업그레이드할 계획이 있으면 먼저 PostgreSQL을 업그레이드합니다.
- [백업 및 복원 명령](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)을 사용하여 데이터베이스를 나중에 PostgreSQL 버전으로 백업 및 복원할 수 있습니다.
- `postgresql['version']`로 지정된 PostgreSQL 버전이 해당 Linux 패키지 릴리스와 함께 제공되지 않으면 [호환성 표의 기본 버전](https://docs.gitlab.com/administration/package_information/postgresql_versions/)이 활성 상태인 클라이언트 바이너리(예: PostgreSQL 백업/복원 바이너리)를 결정합니다.

다음 예는 PostgreSQL 16을 실행하는 데이터베이스 호스트에서 PostgreSQL 17을 실행하는 다른 데이터베이스 호스트로 업그레이드하고 가동 중지 시간이 발생하는 것을 보여줍니다:

1. [데이터베이스 요구사항](https://docs.gitlab.com/install/requirements/#postgresql)에 따라 설정된 새로운 PostgreSQL 17 데이터베이스 서버를 시작합니다.
1. GitLab Rails 인스턴스에서 `pg_dump` 및 `pg_restore`의 호환 버전이 사용되는지 확인합니다. GitLab 구성을 수정하려면 `/etc/gitlab/gitlab.rb`을 편집하고 `postgresql['version']`의 값을 지정합니다:

   ```ruby
   postgresql['version'] = 17
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. GitLab을 중지합니다(이 단계로 인해 가동 중지 시간이 발생함):

   ```shell
   sudo gitlab-ctl stop
   ```

> [!warning]
> 백업 명령은 PgBouncer를 사용 중인 설치 시 [추가 매개변수](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)가 필요합니다.

1. SKIP 옵션을 사용하여 백업 Rake 작업을 실행하여 데이터베이스만 백업합니다. 백업 파일명을 적어둡니다. 나중에 복원할 때 사용합니다.

   ```shell
   sudo gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,pages,registry
   ```

1. PostgreSQL 16 데이터베이스 호스트를 종료합니다.
1. `/etc/gitlab/gitlab.rb`을 편집하고 `gitlab_rails['db_host']` 설정을 업데이트하여 PostgreSQL 데이터베이스 17 호스트를 가리킵니다.
1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   > [!warning]
   > 백업 명령은 PgBouncer를 사용 중인 설치 시 [추가 매개변수](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)가 필요합니다.

1. 이전에 생성한 데이터베이스 백업 파일을 사용하여 데이터베이스를 복원하고 "이 작업은 이제 `authorized_keys` 파일을 다시 빌드합니다"라는 메시지가 표시될 때 **아니요**로 응답해야 합니다:

   ```shell
   # Use the backup timestamp https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-timestamp
   sudo gitlab-backup restore BACKUP=<backup-timestamp>
   ```

1. GitLab을 시작합니다:

   ```shell
   sudo gitlab-ctl start
   ```

1. PostgreSQL을 새로운 주 릴리스로 업그레이드한 후 효율적인 쿼리 계획을 선택하고 데이터베이스 서버 CPU 부하를 줄이기 위해 테이블 통계를 다시 생성합니다.

   `pg_upgrade`을 사용하여 "업그레이드"한 경우 PostgreSQL 데이터베이스 콘솔에서 다음 쿼리를 실행합니다:

   ```sql
   SET statement_timeout = 0; ANALYZE VERBOSE;
   ```

   `ANALYZE` 명령의 실행 시간은 데이터베이스 크기에 따라 크게 달라질 수 있습니다. 이 작업의 진행 상황을 모니터링하려면 다른 PostgreSQL 데이터베이스 콘솔에서 다음 쿼리를 주기적으로 실행할 수 있습니다. `tables_remaining` 열은 `0`에 도달해야 합니다:

   ```sql
   SELECT
     COUNT(*) AS total_tables,
     SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
   FROM pg_stat_user_tables;
   ```

   업그레이드가 `pg_dump` 및 `pg_restore`를 사용한 경우 PostgreSQL 데이터베이스 콘솔에서 다음 쿼리를 실행합니다:

   ```sql
   SET statement_timeout = 0; VACUUM VERBOSE ANALYZE;
   ```

### 데이터베이스 시드(신규 설치만 해당) {#seed-the-database-fresh-installs-only}

> [!warning]
> 이는 파괴적인 명령입니다. 기존 데이터베이스에서 실행하지 마세요.

Linux 패키지 설치는 외부 데이터베이스를 시드하지 않습니다. 다음 명령을 실행하여 스키마를 가져오고 첫 번째 관리자 사용자를 생성합니다:

```shell
# Remove 'sudo' if you are the 'git' user
sudo gitlab-rake gitlab:setup
```

기본 `root` 사용자의 비밀번호를 지정하려면 `/etc/gitlab/gitlab.rb` 전에 `initial_root_password` 설정을 지정하세요. `gitlab:setup` 명령 위:

```ruby
gitlab_rails['initial_root_password'] = 'nonstandardpassword'
```

공유 러너에 대한 초기 등록 토큰을 지정하려면 `gitlab:setup` 명령을 실행하기 전에 `/etc/gitlab/gitlab.rb`에서 `initial_shared_runners_registration_token` 설정을 지정합니다:

```ruby
gitlab_rails['initial_shared_runners_registration_token'] = 'token'
```

### 패키지된 PostgreSQL 버전 고정(신규 설치만 해당) {#pin-the-packaged-postgresql-version-fresh-installs-only}

Linux 패키지는 [다양한 PostgreSQL 버전](https://docs.gitlab.com/administration/package_information/postgresql_versions/)과 함께 제공되며 다르게 지정하지 않으면 기본 버전을 초기화합니다.

PostgreSQL을 기본값이 아닌 버전으로 초기화하려면 `postgresql['version']`을 초기 재구성 전 [패키지된 PostgreSQL 버전](https://docs.gitlab.com/administration/package_information/postgresql_versions/) 중 주 버전 하나로 설정할 수 있습니다. 예를 들어 GitLab 18.11에서 `postgresql['version'] = 16`을 사용하여 기본 PostgreSQL 17 대신 PostgreSQL 16을 사용할 수 있습니다.

> [!warning]
> `postgresql['version']`를 설정하는 것 은 초기 재구성 후 Linux 패키지와 함께 패키지된 PostgreSQL을 사용하면 PostgreSQL의 다른 버전에서 초기화된 데이터 디렉토리에 대한 오류가 발생합니다. 이를 만나면 [패키지된 PostgreSQL 서버를 이전 버전으로 되돌리기](#revert-packaged-postgresql-server-to-the-previous-version)를 참조하세요.

이전에 GitLab이 설치된 환경에서 새로 설치하고 있으며 고정된 PostgreSQL 버전을 사용하는 경우 먼저 PostgreSQL과 관련된 모든 폴더가 삭제되고 인스턴스에서 PostgreSQL 프로세스가 실행 중이 아닌지 확인합니다.

## 일반 텍스트 저장소 없이 GitLab Rails에 민감한 데이터 구성 제공 {#provide-sensitive-data-configuration-to-gitlab-rails-without-plain-text-storage}

자세한 내용은 [구성 문서](configuration.md#provide-the-postgresql-user-password-to-gitlab-rails)의 예를 참조하세요.

## 데이터베이스의 애플리케이션 설정 {#application-settings-for-the-database}

### 자동 데이터베이스 마이그레이션 비활성화 {#disabling-automatic-database-migration}

여러 GitLab 서버가 데이터베이스를 공유하는 경우 재구성 중에 마이그레이션 단계를 수행하는 노드 수를 제한하려고 할 것입니다.

`/etc/gitlab/gitlab.rb`을 편집하여 추가합니다:

```ruby
# Enable or disable automatic database migrations
# on all hosts except the designated deploy node
gitlab_rails['auto_migrate'] = false
```

`/etc/gitlab/gitlab.rb`은 일반 텍스트 비밀번호를 포함하므로 `0600` 파일 권한이 있어야 합니다.

다음에 위의 구성을 수행하는 호스트가 재구성될 때 마이그레이션 단계가 수행되지 않습니다.

스키마 관련 사후 업그레이드 오류를 피하려면 [배포 노드](https://docs.gitlab.com/update/zero_downtime/)로 표시된 호스트는 업그레이드 중에 `gitlab_rails['auto_migrate'] = true`를 포함해야 합니다.

### 클라이언트 `statement_timeout` 설정 {#setting-client-statement_timeout}

Rails이 데이터베이스 트랜잭션이 완료될 때까지 기다릴 시간은 이제 `gitlab_rails['db_statement_timeout']` 설정으로 조정할 수 있습니다. 기본적으로 이 설정은 사용되지 않습니다.

`/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

```ruby
gitlab_rails['db_statement_timeout'] = 45000
```

이 경우 클라이언트 `statement_timeout`이 45초로 설정됩니다. 값은 밀리초 단위로 지정됩니다.

### 연결 타임아웃 설정 {#setting-connection-timeout}

Rails이 PostgreSQL 연결 시도가 성공할 때까지 기다릴 시간은 `gitlab_rails['db_connect_timeout']` 설정으로 조정할 수 있습니다. 기본적으로 이 설정은 사용되지 않습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['db_connect_timeout'] = 5
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

이 경우 클라이언트 `connect_timeout`이 5초로 설정됩니다. 값은 초 단위로 지정됩니다. 최소 2초 값이 적용됩니다. 이를 `<= 0`로 설정하거나 설정을 지정하지 않으면 타임아웃이 비활성화됩니다.

### TCP 제어 설정 {#setting-tcp-controls}

Rails PostgreSQL 어댑터는 성능 개선을 위해 조정할 수 있는 일련의 TCP 연결 제어를 제공합니다. [각 매개변수에 대한 자세한 내용은 PostgreSQL 업스트림 문서](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-KEEPALIVES)를 참조하세요.

Linux 패키지는 이러한 값에 대한 기본값을 설정하지 않으며 대신 PostgreSQL 어댑터에서 제공하는 기본값을 사용합니다. `gitlab.rb`에서 이를 재정의하고 아래 표에 나열된 매개변수를 사용한 다음 `gitlab-ctl reconfigure`을 실행합니다.

| PostgreSQL 매개변수  | `gitlab.rb` 매개변수 |
|-----------------------|-----------------------|
| `keepalives`          | `gitlab_rails['db_keepalives']` |
| `keepalives_idle`     | `gitlab_rails['db_keepalives_idle']` |
| `keepalives_interval` | `gitlab_rails['db_keepalives_interval']` |
| `keepalives_count`    | `gitlab_rails['db_keepalives_count']` |
| `tcp_user_timeout`    | `gitlab_rails['db_tcp_user_timeout']` |

## 자동 데이터베이스 리인덱싱 {#automatic-database-reindexing}

> [!warning]
> 이는 기본적으로 활성화되지 않은 실험적 기능입니다.

백그라운드에서 데이터베이스 인덱스를 다시 생성합니다("리인덱싱"이라고 함). 이를 사용하여 인덱스에 축적된 부풀어진 공간을 제거하고 건강하고 효율적인 인덱스를 유지할 수 있습니다.

리인덱싱 작업은 정기적으로 cronjob을 통해 시작할 수 있습니다. cronjob을 구성하려면 `gitlab_rails['database_reindexing']['enable']`이 `true`로 설정되어야 합니다.

다중 노드 환경에서 이 기능은 애플리케이션 호스트에서만 활성화되어야 합니다. 리인덱싱 프로세스는 PgBouncer를 통해 이동할 수 없으며 직접 데이터베이스 연결이 있어야 합니다.

기본적으로 주말 시간(트래픽이 적은 시간일 가능성이 높음) 중에만 매 시간마다 cronjob을 시작합니다.

다음 설정을 구체화하여 일정을 변경할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```shell
   gitlab_rails['database_reindexing']['hour'] = '*'
   gitlab_rails['database_reindexing']['minute'] = 0
   gitlab_rails['database_reindexing']['month'] = '*'
   gitlab_rails['database_reindexing']['day_of_month'] = '*'
   gitlab_rails['database_reindexing']['day_of_week'] = '0,6'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Helm 차트 인스턴스가 있으면 대신 [Toolbox 차트](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#configure-periodic-database-reindexing)에서 데이터베이스 리인덱싱 CronJob을 활성화할 수 있습니다.

## HA/Geo 클러스터에 배포된 패키지된 PostgreSQL {#packaged-postgresql-deployed-in-an-hageo-cluster}

### GitLab HA 클러스터 업그레이드 {#upgrading-a-gitlab-ha-cluster}

Patroni 클러스터에서 PostgreSQL 버전을 업그레이드하려면 [Patroni 클러스터에서 PostgreSQL 주 버전 업그레이드](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster)를 참조하세요.

### HA 클러스터의 업그레이드 문제 해결 {#troubleshooting-upgrades-in-an-ha-cluster}

어느 시점에서 번들된 PostgreSQL이 HA 설정으로 업그레이드하기 전에 노드에서 실행되고 있었다면 이전 데이터 디렉토리가 남아 있을 수 있습니다. 이로 인해 `gitlab-ctl reconfigure`이 해당 노드에서 사용하는 PostgreSQL 유틸리티의 버전을 다운그레이드합니다. 이를 방지하려면 디렉토리를 이동하거나 제거합니다:

- `mv /var/opt/gitlab/postgresql/data/ /var/opt/gitlab/postgresql/data.$(date +%s)`

`gitlab-ctl repmgr standby setup MASTER_NODE_NAME`을 사용하여 보조 노드를 다시 생성할 때 다음 오류가 발생하면 `postgresql['max_replication_slots'] = X`(여기서 `X`는 DB 노드 + 1의 개수)가 `/etc/gitlab/gitlab.rb`에 포함되어 있는지 확인합니다:

```shell
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Geo 인스턴스 업그레이드 {#upgrading-a-geo-instance}

Geo는 기본적으로 PostgreSQL 스트리밍 복제에 의존하므로 GitLab을 업그레이드할 때 및 PostgreSQL을 업그레이드할 때 추가 고려사항이 있습니다.

#### Geo로 PostgreSQL을 업그레이드할 때의 주의사항 {#caveats-when-upgrading-postgresql-with-geo}

> [!warning]
> Geo를 사용할 때 PostgreSQL을 업그레이드하려면 Geo **secondaries**에 PostgreSQL 복제를 다시 초기화해야 하므로 모든 보조 서버에서 가동 중지 시간이 필요합니다. 이는 PostgreSQL 스트리밍 복제의 작동 방식 때문입니다. 복제를 다시 초기화하면 기본 서버에서 모든 데이터를 다시 복사하므로 주로 데이터베이스 크기와 사용 가능한 대역폭에 따라 오래 걸릴 수 있습니다. 예를 들어 30Mbps의 전송 속도와 100GB의 데이터베이스 크기에서 재동기화하는 데 약 8시간이 걸릴 수 있습니다. [PostgreSQL 문서](https://www.postgresql.org/docs/11/pgupgrade.html)를 참조하세요. 자세한 내용을 확인하세요.

#### Geo를 사용할 때 PostgreSQL을 업그레이드하는 방법 {#how-to-upgrade-postgresql-when-using-geo}

PostgreSQL을 업그레이드하려면 복제 슬롯의 이름과 복제 사용자의 비밀번호가 필요합니다.

1. Geo 기본 데이터베이스 노드에서 기존 복제 슬롯의 이름을 찾으려면 다음을 실행합니다:

   ```shell
   sudo gitlab-psql -qt -c 'select slot_name from pg_replication_slots'
   ```

   여기서 `slot_name`을 찾을 수 없거나 반환된 출력이 없으면 Geo 보조 서버가 정상이 아닐 수 있습니다. 이 경우 [보조 서버가 정상이며 복제가 작동 중](https://docs.gitlab.com/administration/geo/replication/troubleshooting/common/#health-check-rake-task)인지 확인합니다.

   쿼리가 비어 있더라도 [Geo 사이트 관리 영역](https://docs.gitlab.com/administration/geo_sites/)에서 찾은 `slot_name`으로 보조 데이터베이스를 다시 초기화해 볼 수 있습니다.

1. 복제 사용자의 비밀번호를 수집합니다. 이는 Geo 설정 중에 [Step 1로 설정되었습니다. 기본 사이트 구성](https://docs.gitlab.com/administration/geo/setup/database/#step-1-configure-the-primary-site).

1. 선택 사항입니다. [각 **세컨더리** 사이트에서 복제를 일시 중지](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication)하여 재해 복구(DR) 기능을 보호합니다.

1. Geo 기본 서버에서 PostgreSQL을 수동으로 업그레이드합니다. Geo 기본 데이터베이스 노드에서 실행합니다:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

   **primary database** 업그레이드가 완료될 때까지 기다립니다. 그 후 보조 서버가 백업으로 준비된 상태를 유지할 수 있도록 다음 단계를 시작합니다. 그 후 **tracking database**를 **secondary database**와 병렬로 업그레이드할 수 있습니다.

1. Geo 보조 서버에서 PostgreSQL을 수동으로 업그레이드합니다. Geo **secondary database**와 **tracking database**에서 실행합니다:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

1. Geo **secondary database**의 데이터베이스 복제를 다시 시작합니다. 명령을 사용하여:

   ```shell
   sudo gitlab-ctl replicate-geo-database --slot-name=SECONDARY_SLOT_NAME --host=PRIMARY_HOST_NAME --sslmode=verify-ca
   ```

   기본 서버의 복제 사용자 비밀번호를 입력하라는 메시지가 표시됩니다. `SECONDARY_SLOT_NAME`을 위의 첫 번째 단계에서 검색한 슬롯 이름으로 바꿉니다.

   이 작업의 기본 타임아웃은 30분입니다. 타임아웃을 늘려야 하면 `--backup-timeout` 옵션을 설정합니다. 예를 들어 `--backup-timeout=21600`는 초기 복제에 6시간을 제공합니다.

1. Geo **secondary database**에서 [GitLab을 재구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)하여 `pg_hba.conf` 파일을 업데이트합니다. 이는 `replicate-geo-database`이 기본 파일을 보조 서버로 복제하기 때문에 필요합니다.

1. 3단계에서 복제를 일시 중지했으면 [각 **세컨더리** 에서 복제를 다시 시작](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication)합니다.

1. `puma`, `sidekiq` 및 `geo-logcursor`을 다시 시작합니다.

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. `https://your_primary_server/admin/geo/sites`로 이동하고 모든 Geo 사이트가 정상인지 확인합니다.

## PostgreSQL 데이터베이스에 연결 {#connecting-to-the-postgresql-database}

PostgreSQL 데이터베이스에 연결해야 하면 애플리케이션 사용자로 연결할 수 있습니다:

```shell
sudo gitlab-rails dbconsole --database main
```

## 문제 해결 {#troubleshooting}

### `default_transaction_isolation`을 `read committed`로 설정 {#set-default_transaction_isolation-into-read-committed}

`production/sidekiq` 로그에서 다음과 유사한 오류가 표시되면:

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

데이터베이스의 `default_transaction_isolation` 구성이 GitLab 애플리케이션 요구사항과 일치하지 않을 수 있습니다. PostgreSQL 데이터베이스에 연결하고 `SHOW default_transaction_isolation;`을 실행하여 이 구성을 확인할 수 있습니다. GitLab 애플리케이션은 `read committed`을 구성하도록 기대합니다.

이 `default_transaction_isolation` 구성은 `postgresql.conf` 파일에 설정됩니다. 구성을 변경한 후 데이터베이스를 다시 시작/다시 로드해야 합니다. 이 구성은 Linux 패키지에 포함된 패키지된 PostgreSQL 서버에서 기본값으로 제공됩니다.

### 라이브러리를 로드할 수 없음 `plpgsql.so` {#could-not-load-library-plpgsqlso}

데이터베이스 마이그레이션을 실행하는 동안 또는 PostgreSQL/Patroni 로그에서 다음과 유사한 오류가 표시될 수 있습니다:

```plaintext
ERROR:  could not load library "/opt/gitlab/embedded/postgresql/12/lib/plpgsql.so": /opt/gitlab/embedded/postgresql/12/lib/plpgsql.so: undefined symbol: EnsurePortalSnapshotExists
```

이 오류는 기본 버전 변경 후 PostgreSQL을 다시 시작하지 않았기 때문에 발생합니다. 이 오류를 해결하려면:

1. 다음 명령 중 하나를 실행합니다:

   ```shell
   # For PostgreSQL
   sudo gitlab-ctl restart postgresql

   # For Patroni
   sudo gitlab-ctl restart patroni

   # For Geo PostgreSQL
   sudo gitlab-ctl restart geo-postgresql
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 데이터베이스 CPU 로드가 매우 높음 {#database-cpu-load-very-high}

데이터베이스 CPU 로드가 매우 높으면 [자동 취소 중복 파이프라인 설정](https://docs.gitlab.com/ci/pipelines/settings/#auto-cancel-redundant-pipelines)으로 인해 발생할 수 있습니다. 자세한 내용은 [이슈 435250](https://gitlab.com/gitlab-org/gitlab/-/issues/435250)을 참조하세요.

이 이슈를 해결하려면:

- 데이터베이스 서버에 더 많은 CPU 리소스를 할당할 수 있습니다.
- Sidekiq이 과부하 상태이면 프로젝트에 매우 많은 파이프라인이 있으면 `ci_cancel_redundant_pipelines` 큐에 대해 [더 많은 Sidekiq 프로세스를 추가](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#start-multiple-processes)해야 할 수도 있습니다.
- `disable_cancel_redundant_pipelines_service` 기능 플래그를 활성화하여 이 설정을 인스턴스 전체에서 비활성화하고 CPU 로드가 내려가는지 확인할 수 있습니다. 이렇게 하면 모든 프로젝트에 대한 기능이 비활성화되고 더 이상 자동으로 취소되지 않는 파이프라인으로 인한 리소스 사용량이 증가할 수 있습니다.

### 오류: `TypeError: can't quote Array` {#error-typeerror-cant-quote-array}

Amazon RDS를 사용 중인 경우 `gitlab::database_migrations` 작업 중에 오류가 표시될 수 있습니다. `TypeError: can't quote Array`

이 [알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/356307) 를 해결하려면 PostgreSQL 데이터베이스용 RDS에서 [`quote_all_identifiers`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html) 매개변수를 비활성화합니다.
