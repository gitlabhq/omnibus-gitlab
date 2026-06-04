---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 백업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## Linux 패키지 설치에서 백업 및 복원 구성 {#backup-and-restore-configuration-on-a-linux-package-installation}

Linux 패키지 설치의 모든 구성은 `/etc/gitlab`에 저장됩니다. [구성 및 인증서](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#data-not-included-in-a-backup)의 복사본을 GitLab 애플리케이션 백업과 별도의 안전한 위치에 보관해야 합니다. 이렇게 하면 암호화된 애플리케이션 데이터가 손실되거나 유출되거나 암호를 해독하는 데 필요한 키와 함께 도용될 확률을 줄입니다.

특히 `gitlab-secrets.json` 파일(및 가능하면 `gitlab.rb` 파일)은 SQL 데이터베이스에서 민감한 데이터를 보호하기 위한 데이터베이스 암호화 키를 포함합니다:

- [2단계 인증](https://docs.gitlab.com/security/two_factor_authentication/)(2FA) 사용자 시크릿
- [안전한 파일](https://docs.gitlab.com/ci/secure_files/)

이 파일들이 손실되면 2FA 사용자는 자신의 [GitLab 계정](https://docs.gitlab.com/user/profile/)에 접근할 수 없게 되며 CI 구성에서 '안전한 변수'가 손실됩니다.

구성을 백업하려면 `sudo gitlab-ctl backup-etc`을 실행하세요. `/etc/gitlab/config_backup/`에 tar 아카이브를 만듭니다. 디렉토리 및 백업 파일은 root만 읽을 수 있습니다.

> [!note]
> `sudo gitlab-ctl backup-etc --backup-path <DIRECTORY>`을 실행하면 지정된 디렉토리에 백업이 저장됩니다. 디렉토리가 존재하지 않으면 생성됩니다. 절대 경로를 권장합니다.

일일 애플리케이션 백업을 만들려면 root 사용자의 cron 테이블을 편집하세요:

```shell
sudo crontab -e -u root
```

cron 테이블이 편집기에 나타납니다.

`/etc/gitlab/`의 내용을 포함하는 tar 파일을 만드는 명령을 입력하세요. 예를 들어 평일 화요일(2일)부터 토요일(6일)까지 매일 아침 백업을 실행하도록 예약합니다:

```plaintext
15 04 * * 2-6  gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/
```

> [!note]
> `/secret/gitlab/backups/`가 존재하는지 확인하세요.

tar 파일을 다음과 같이 추출할 수 있습니다.

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf gitlab_config_1487687824_2017_02_21.tar -C /
```

구성 백업을 복원한 후 `sudo gitlab-ctl reconfigure`을 실행하세요.

> [!note]
> 머신의 SSH 호스트 키는 `/etc/ssh/`의 별도 위치에 저장됩니다. 전체 머신 복원을 수행해야 하는 경우 중간자 공격 경고를 방지하기 위해 [이 키들을 백업 및 복원](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)해야 합니다.

### 구성 백업의 백업 수명 제한(오래된 백업 삭제) {#limit-backup-lifetime-for-configuration-backups-prune-old-backups}

GitLab 구성 백업은 `backup_keep_time` 설정을 사용하여 삭제할 수 있으며, 이는 [GitLab 애플리케이션 백업에 사용됩니다](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#limit-backup-lifetime-for-local-files-prune-old-backups)

이 설정을 사용하려면 `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

기본 `backup_keep_time` 설정은 `0`이며, 모든 GitLab 구성 및 애플리케이션 백업을 유지합니다.

`backup_keep_time`이 설정되면 `sudo gitlab-ctl backup-etc --delete-old-backups`을 실행하여 현재 시간에서 `backup_keep_time`을 뺀 시간보다 오래된 모든 백업을 삭제할 수 있습니다.

모든 기존 백업을 유지하려면 `--no-delete-old-backups` 매개변수를 제공할 수 있습니다.

> [!warning]
> 매개변수가 제공되지 않으면 기본값은 `--delete-old-backups`이며, `backup_keep_time`이 0보다 크면 현재 시간에서 `backup_keep_time`을 뺀 시간보다 오래된 모든 백업을 삭제합니다.

## 애플리케이션 백업 만들기 {#creating-an-application-backup}

저장소 및 GitLab 메타데이터의 백업을 만들려면 [백업 생성 설명서](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)를 따르세요.

백업 생성은 tar 파일을 `/var/opt/gitlab/backups`에 저장합니다.

GitLab 백업을 다른 디렉토리에 저장하려면 `/etc/gitlab/gitlab.rb`에 다음 설정을 추가하고 `sudo gitlab-ctl
reconfigure`을 실행하세요:

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

## Docker 컨테이너에서 GitLab 인스턴스에 대한 백업 만들기 {#creating-backups-for-gitlab-instances-in-docker-containers}

> [!warning]
> 백업 명령은 설치가 PgBouncer를 사용 중일 때 [추가 매개변수](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)가 필요하며, 성능상의 이유 또는 Patroni 클러스터와 함께 사용할 때 필요합니다.

호스트에서 `docker exec -t <your container name>`을 앞에 붙여 백업을 예약할 수 있습니다.

백업 애플리케이션:

```shell
docker exec -t <your container name> gitlab-backup
```

백업 구성 및 시크릿:

```shell
docker exec -t <your container name> /bin/sh -c 'gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/'
```

> [!note]
> 이 백업들을 컨테이너 외부에 유지하려면 다음 디렉토리에 볼륨을 마운트하세요:

1. `/secret/gitlab/backups`.
1. `/var/opt/gitlab` (백업 포함 [모든 애플리케이션 데이터](https://docs.gitlab.com/install/docker/installation/#create-a-directory-for-the-volumes)의 경우)
1. `/var/opt/gitlab/backups` (선택사항). `gitlab-backup` 도구는 이 디렉토리에 [기본적으로](#creating-an-application-backup) 씁니다. 이 디렉토리가 `/var/opt/gitlab` 내에 중첩되어 있는 동안 [Docker가 이 마운트들을 정렬](https://github.com/moby/moby/pull/8055)하여 조화롭게 작동할 수 있습니다.

   이 구성은 예를 들어 다음을 가능하게 합니다:

   - 일반 로컬 스토리지(두 번째 마운트를 통해)의 애플리케이션 데이터.
   - 네트워크 스토리지(세 번째 마운트를 통해)의 백업 볼륨.

## 애플리케이션 백업 복원 {#restoring-an-application-backup}

[복원 설명서](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/)를 참조하세요.

## 패키지되지 않은 데이터베이스를 사용한 백업 및 복원 {#backup-and-restore-using-non-packaged-database}

패키지되지 않은 데이터베이스를 사용 중인 경우 [패키지되지 않은 데이터베이스 사용에 대한 설명서](database.md#using-a-non-packaged-postgresql-database-management-server)를 참조하세요.

## 백업을 원격(클라우드) 스토리지에 업로드 {#upload-backups-to-remote-cloud-storage}

자세한 내용은 [백업 설명서](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage)를 확인하세요.

## 백업 디렉토리 수동 관리 {#manually-manage-backup-directory}

Linux 패키지 설치는 `gitlab_rails['backup_path']`로 설정된 백업 디렉토리를 만듭니다. 이 디렉토리는 GitLab을 실행 중인 사용자가 소유하며 해당 사용자만 접근할 수 있도록 엄격한 권한이 설정되어 있습니다. 이 디렉토리는 백업 아카이브를 보유하며 민감한 정보를 포함합니다. 일부 조직에서는 예를 들어 백업 아카이브를 원격지에 보내야 하기 때문에 권한이 다를 필요가 있습니다.

백업 디렉토리 관리를 비활성화하려면 `/etc/gitlab/gitlab.rb`에 다음을 설정하세요:

```ruby
gitlab_rails['manage_backup_path'] = false
```

> [!warning]
> 이 구성 옵션을 설정하면 `gitlab_rails['backup_path']`에 지정된 디렉토리를 만들고 `user['username']`에 지정된 사용자가 올바른 액세스 권한을 가질 수 있도록 권한을 설정해야 합니다. 이를 수행하지 않으면 GitLab이 백업 아카이브를 만들 수 없습니다.

## 컨테이너 레지스트리 메타데이터 데이터베이스 백업 자격증명 {#container-registry-metadata-database-backup-credentials}

{{< history >}}

- GitLab [18.11](https://gitlab.com/groups/gitlab-org/-/work_items/21179)에서 [도입됨].

{{< /history >}}

`gitlab-backup`을 사용하여 컨테이너 레지스트리 메타데이터 데이터베이스를 백업할 때 GitLab은 레지스트리 PostgreSQL 데이터베이스에 연결할 수 있는 자격증명을 저장해야 합니다. 이 자격증명은 디스크의 제한된 파일에 기록되고 런타임에 백업 도구에 의해 선택됩니다.

### 백업 역할 활성화 {#enable-the-backup-role}

레지스트리 자격증명 파일 생성을 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['backup_role'] = true
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 단일 노드 설치 {#single-node-installations}

컨테이너 레지스트리가 GitLab과 함께 배치된 단일 노드 설치에서 데이터베이스 연결 설정은 `registry['database']` 구성에서 자동으로 파생됩니다. 백업 및 복원 PostgreSQL 역할에 대한 자격증명만 설정해야 합니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['backup_role'] = true

   # Credentials for the PostgreSQL role used when creating backups
   gitlab_rails['backup_registry_user']     = 'registry_backup'  # default
   gitlab_rails['backup_registry_password'] = '<backup_password>'

   # Credentials for the PostgreSQL role used when restoring backups
   gitlab_rails['restore_registry_user']     = 'registry_restore'  # default
   gitlab_rails['restore_registry_password'] = '<restore_password>'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 다중 노드 설치(전용 백업 노드) {#multi-node-installations-dedicated-backup-node}

다중 노드 설치의 경우 또는 컨테이너 레지스트리가 함께 배치되지 않은 전용 백업 노드에서 `gitlab-backup`을 실행할 때 연결 세부사항을 명시적으로 지정하세요:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['backup_role'] = true

   gitlab_rails['backup_registry']['database_connection'] = {
     'host'        => 'registry-db.example.com',
     'port'        => 5432,           # default
     'dbname'      => 'registry',     # default
     'sslmode'     => 'require',
     'sslcert'     => '/path/to/client.crt',
     'sslkey'      => '/path/to/client.key',
     'sslrootcert' => '/path/to/ca.crt'
   }

   gitlab_rails['backup_registry_user']      = 'registry_backup'
   gitlab_rails['backup_registry_password']  = '<backup_password>'
   gitlab_rails['restore_registry_user']     = 'registry_restore'
   gitlab_rails['restore_registry_password'] = '<restore_password>'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 자격증명 파일 {#credential-files}

`sudo gitlab-ctl reconfigure` 후 `/opt/gitlab/etc/gitlab-backup/env/` 아래에 다음 파일들이 생성됩니다:

| 파일 | 작성된 환경 변수 |
| ---- | ----------------------------- |
| `env-connection` | `REGISTRY_DATABASE_HOST`, `REGISTRY_DATABASE_PORT`, `REGISTRY_DATABASE_NAME`, `REGISTRY_DATABASE_SSLMODE`, `REGISTRY_DATABASE_SSLCERT`, `REGISTRY_DATABASE_SSLKEY`, `REGISTRY_DATABASE_SSLROOTCERT` |
| `env-backup_user` | `REGISTRY_DATABASE_USER`, `REGISTRY_DATABASE_PASSWORD` (백업 역할 자격증명) |
| `env-restore_user` | `REGISTRY_DATABASE_USER`, `REGISTRY_DATABASE_PASSWORD` (복원 역할 자격증명) |

모든 파일은 `root:root`로 소유되며 `0400` 권한을 가집니다. 상위 디렉토리는 `0750` 권한을 가집니다. 비어있지 않은 값만 파일에 기록됩니다.
