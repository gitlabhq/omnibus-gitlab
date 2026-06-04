---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 설치를 위한 구성 옵션
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab을 구성하려면 `/etc/gitlab/gitlab.rb` 파일에서 관련 옵션을 설정합니다.

[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)에는 사용 가능한 모든 옵션의 전체 목록이 포함되어 있습니다. 새 설치에는 기본적으로 `/etc/gitlab/gitlab.rb`에 템플릿의 모든 옵션이 나열되어 있습니다.

> [!note]
> `/etc/gitlab/gitlab.rb`을 편집할 때 제공되는 예제가 항상 인스턴스의 기본 설정을 반영하지는 못할 수 있습니다.

기본 설정 목록은 [패키지 기본값](https://docs.gitlab.com/administration/package_information/defaults/)을 참조하세요.

## GitLab의 외부 URL 구성 {#configure-the-external-url-for-gitlab}

사용자에게 올바른 리포지토리 복제 링크를 표시하려면 사용자가 리포지토리에 도달하기 위해 사용하는 URL을 GitLab에 제공해야 합니다. 서버의 IP를 사용할 수 있지만 FQDN(완전히 정규화된 도메인 이름)을 권장합니다. GitLab Self-Managed 인스턴스에서 DNS 사용에 대한 자세한 내용은 [DNS 설명서](dns.md)를 참조하세요.

외부 URL을 변경하려면:

1. 선택 사항입니다. 외부 URL을 변경하기 전에 이전에 [사용자 정의 **홈페이지 URL** 또는 **After sign-out path**](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#sign-in-information)를 정의했는지 확인하세요. 이러한 설정 중 하나라도 새 외부 URL을 구성한 후 의도하지 않은 리디렉션을 발생시킬 수 있습니다. URL을 정의한 경우 완전히 제거하세요.

1. `/etc/gitlab/gitlab.rb`을 편집하고 `external_url`를 원하는 URL로 변경합니다:

   ```ruby
   external_url "http://gitlab.example.com"
   ```

   또는 서버의 IP 주소를 사용할 수 있습니다:

   ```ruby
   external_url "http://10.0.0.1"
   ```

   이전 예제에서는 순수 HTTP를 사용합니다. HTTPS를 사용하려면 [SSL 구성](ssl/_index.md) 방법을 참조하세요.

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 선택 사항입니다. GitLab을 오래 사용한 후 외부 URL을 변경하면 [Markdown 캐시를 무효화](https://docs.gitlab.com/administration/invalidate_markdown_cache/)해야 합니다.

### 설치 시점에 외부 URL 지정 {#specify-the-external-url-at-the-time-of-installation}

Linux 패키지를 사용하는 경우 `EXTERNAL_URL` 환경 변수를 사용하여 최소한의 명령 수로 GitLab 인스턴스를 설정할 수 있습니다. 이 변수를 설정하면 자동으로 감지되고 해당 값이 `gitlab.rb` 파일에 `external_url`로 기록됩니다.

`EXTERNAL_URL` 환경 변수는 패키지 설치 및 업그레이드에만 영향을 줍니다. 정기적인 재구성 실행의 경우 `/etc/gitlab/gitlab.rb`의 값이 사용됩니다.

패키지 업데이트의 일부로 `EXTERNAL_URL` 변수를 실수로 설정했으면 경고 없이 `/etc/gitlab/gitlab.rb`의 기존 값을 바꿉니다. 따라서 변수를 전역적으로 설정하지 않고 설치 명령에만 전달하는 것이 좋습니다:

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee
```

## GitLab의 상대 URL 구성 {#configure-a-relative-url-for-gitlab}

{{< details >}}

- 상태:  베타

{{< /details >}}

> [!warning]
> GitLab의 상대 URL 구성에는 [Geo의 알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/456427) 와 [테스트 제한](https://gitlab.com/gitlab-org/gitlab/-/issues/439943)이 있습니다.

GitLab을 자신의 (하위) 도메인에 설치할 것을 권장하지만 때로는 불가능할 수 있습니다. 이 경우 GitLab을 상대 URL 아래(예: `https://example.com/gitlab`)에 설치할 수도 있습니다.

URL을 변경하면 모든 원격 URL도 변경되므로 GitLab 인스턴스를 가리키는 로컬 리포지토리에서 URL을 수동으로 편집해야 합니다.

이 지침은 Linux 패키지 설치를 위한 것입니다. 자체 컴파일(소스) 설치에 대한 지침은 [GitLab을 상대 URL 아래에 설치](https://docs.gitlab.com/install/relative_url/)를 참조하세요.

GitLab에서 상대 URL을 활성화하려면:

1. `/etc/gitlab/gitlab.rb`에서 `external_url`을 설정합니다:

   ```ruby
   external_url "https://example.com/gitlab"
   ```

   이 예제에서 GitLab이 제공되는 상대 URL은 `/gitlab`입니다. 필요한 대로 변경하세요.

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

이슈가 있으면 [이슈 해결 섹션](#relative-url-troubleshooting)을 참조하세요.

## 루트가 아닌 사용자로부터 외부 구성 파일 로드 {#load-external-configuration-file-from-non-root-user}

Linux 패키지 설치는 `/etc/gitlab/gitlab.rb` 파일에서 모든 구성을 로드합니다. 이 파일은 엄격한 파일 권한이 있으며 `root` 사용자가 소유합니다. 엄격한 권한과 소유권의 이유는 `/etc/gitlab/gitlab.rb`가 `gitlab-ctl reconfigure` 중에 `root` 사용자에 의해 Ruby 코드로 실행되기 때문입니다. 이는 `/etc/gitlab/gitlab.rb`에 쓰기 액세스 권한이 있는 사용자가 `root`에 의해 코드로 실행되는 구성을 추가할 수 있음을 의미합니다.

특정 조직에서는 구성 파일에 액세스할 수 있지만 루트 사용자로는 액세스할 수 없습니다. 파일 경로를 지정하여 `/etc/gitlab/gitlab.rb` 내에 외부 구성 파일을 포함할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   from_file "/home/admin/external_gitlab.rb"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`from_file`을 사용할 때:

- `/etc/gitlab/gitlab.rb`에 `from_file`를 사용하여 포함시킨 코드는 GitLab을 재구성할 때 `root` 권한으로 실행됩니다.
- `/etc/gitlab/gitlab.rb`에서 `from_file`를 포함한 후 설정된 모든 구성은 포함된 파일의 구성보다 우선합니다.

## 파일에서 인증서 읽기 {#read-certificate-from-file}

인증서를 별도 파일로 저장하고 `sudo gitlab-ctl reconfigure`을 실행할 때 메모리에 로드할 수 있습니다. 인증서를 포함하는 파일은 순수 텍스트여야 합니다.

이 예제에서 [PostgreSQL 서버 인증서](database.md#configuring-ssl)는 `/etc/gitlab/gitlab.rb`에 직접 복사하여 붙여넣지 않고 파일에서 직접 읽습니다.

```ruby
postgresql['internal_certificate'] = File.read('/path/to/server.crt')
```

## `git_data_dirs` 마이그레이션 {#migrating-from-git_data_dirs}

18.0부터 `git_data_dirs`은 더 이상 Gitaly 스토리지 위치를 구성하는 지원되는 방법이 아닙니다. `git_data_dirs`를 명시적으로 정의하면 구성을 마이그레이션해야 합니다.

예를 들어 Gitaly 서비스의 경우 `/etc/gitlab/gitlab.rb` 구성이 다음과 같으면:

```ruby
git_data_dirs({
  "default" => {
    "path" => "/mnt/nas/git-data"
   }
})
```

`gitaly['configuration']` 아래에서 구성을 다시 정의해야 합니다. `/repositories` 접미사는 이전에 내부적으로 추가되었기 때문에 경로에 추가되어야 합니다.

```ruby
gitaly['configuration'] = {
  storage: [
    {
      name: 'default',
      path: '/mnt/nas/git-data/repositories',
    },
  ],
}
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

`path`의 상위 디렉터리도 Omnibus에서 관리해야 한다는 점이 중요합니다. 위의 예에 따라 Omnibus는 재구성 시 `/mnt/nas/git-data`의 권한을 수정해야 하며 런타임 중에 해당 디렉터리에 데이터를 저장할 수 있습니다. 이 동작을 허용하는 적절한 `path`을 선택해야 합니다.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

Rails 및 Sidekiq 클라이언트의 경우 `/etc/gitlab/gitlab.rb` 구성이 다음과 같으면:

```ruby
git_data_dirs({
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
   }
})
```

`gitlab_rails['repositories_storages']` 아래에서 구성을 다시 정의해야 합니다:

```ruby
gitlab_rails['repositories_storages'] = {
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
  }
}
```

## Git 데이터를 대체 디렉터리에 저장 {#store-git-data-in-an-alternative-directory}

기본적으로 Linux 패키지 설치는 `/var/opt/gitlab/git-data/repositories` 아래에 Git 리포지토리 데이터를 저장하고 Gitaly 서비스는 `unix:/var/opt/gitlab/gitaly/gitaly.socket`에서 수신 대기합니다.

디렉터리 위치를 변경하려면,

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

   여러 Git 데이터 디렉터리를 추가할 수도 있습니다:

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
       },
       {
         name: 'alternative',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 선택 사항입니다. `/var/opt/gitlab/git-data`에 기존 Git 리포지토리가 이미 있으면 새 위치로 이동할 수 있습니다:
   1. 리포지토리를 이동하는 동안 사용자가 리포지토리에 쓰는 것을 방지합니다:

      ```shell
      sudo gitlab-ctl stop
      ```

   1. 리포지토리를 새 위치로 동기화합니다. `repositories` 뒤에 _슬래시 없음_이 있지만 `git-data` 뒤에 _슬래시 있음_을 참조하세요:

      ```shell
      sudo rsync -av --delete /var/opt/gitlab/git-data/repositories /mnt/nas/git-data/
      ```

   1. 재구성하여 필요한 프로세스를 시작하고 잘못된 권한을 수정합니다:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. `/mnt/nas/git-data/`에서 디렉터리 레이아웃을 다시 확인하세요. 예상 출력은 `repositories`이어야 합니다:

      ```shell
      sudo ls /mnt/nas/git-data/
      ```

   1. GitLab을 시작하고 웹 인터페이스에서 리포지토리를 탐색할 수 있는지 확인합니다:

      ```shell
      sudo gitlab-ctl start
      ```

별도의 서버에서 Gitaly를 실행 중이면 [Gitaly 구성 설명서](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-gitaly-clients)를 참조하세요.

모든 리포지토리를 이동하지 않고 기존 리포지토리 저장소 간에 특정 프로젝트를 이동하려면 [Edit Project API](https://docs.gitlab.com/api/projects/#edit-a-project) 엔드포인트를 사용하고 `repository_storage` 속성을 지정합니다.

## Git 사용자 또는 그룹의 이름 변경 {#change-the-name-of-the-git-user-or-group}

> [!warning]
> 기존 설치의 사용자 또는 그룹을 변경하면 예측할 수 없는 부작용이 발생할 수 있으므로 권장하지 않습니다.

기본적으로 Linux 패키지 설치는 Git GitLab Shell 로그인, Git 데이터 자체의 소유권 및 웹 인터페이스의 SSH URL 생성을 위해 `git` 사용자 이름을 사용합니다. 마찬가지로 `git` 그룹은 Git 데이터의 그룹 소유권에 사용됩니다.

새 Linux 패키지 설치에서 사용자 및 그룹을 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   user['username'] = "gitlab"
   user['group'] = "gitlab"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

기존 설치의 사용자 이름을 변경하는 경우 재구성 실행은 중첩된 디렉터리의 소유권을 변경하지 않으므로 수동으로 변경해야 합니다.

최소한 리포지토리 및 업로드 디렉터리의 소유권을 변경해야 합니다:

```shell
sudo chown -R gitlab:gitlab /var/opt/gitlab/git-data/repositories
sudo chown -R gitlab:gitlab /var/opt/gitlab/gitlab-rails/uploads
```

## 숫자 사용자 및 그룹 식별자 지정 {#specify-numeric-user-and-group-identifiers}

Linux 패키지 설치는 GitLab, PostgreSQL, Redis, NGINX 등을 위한 사용자를 생성합니다. 이러한 사용자의 숫자 식별자를 지정하려면:

1. 나중에 필요할 수 있으므로 이전 사용자 및 그룹 식별자를 기록해 둡니다:

   ```shell
   sudo cat /etc/passwd
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 원하는 식별자를 변경합니다:

   ```ruby
   user['uid'] = 1234
   user['gid'] = 1234
   postgresql['uid'] = 1235
   postgresql['gid'] = 1235
   redis['uid'] = 1236
   redis['gid'] = 1236
   web_server['uid'] = 1237
   web_server['gid'] = 1237
   registry['uid'] = 1238
   registry['gid'] = 1238
   prometheus['uid'] = 1240
   prometheus['gid'] = 1240
   ```

1. GitLab을 중지했다가 재구성한 후 시작합니다:

   ```shell
   sudo gitlab-ctl stop
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl start
   ```

1. 선택 사항입니다. `user['uid']` 및 `user['gid']`를 변경하는 경우 예를 들어 로그와 같이 Linux 패키지에서 직접 관리하지 않는 파일의 uid/guid를 업데이트해야 합니다:

   ```shell
   find /var/log/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/log/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   find /var/opt/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/opt/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   ```

## 사용자 및 그룹 계정 관리 비활성화 {#disable-user-and-group-account-management}

기본적으로 Linux 패키지 설치는 시스템 사용자 및 그룹 계정을 생성하고 정보를 최신 상태로 유지합니다. 이러한 시스템 계정은 패키지의 다양한 구성 요소를 실행합니다. 대부분의 사용자는 이 동작을 변경할 필요가 없습니다. 하지만 시스템 계정이 예를 들어 LDAP과 같은 다른 소프트웨어에서 관리되는 경우 GitLab 패키지에서 수행하는 계정 관리를 비활성화해야 할 수 있습니다.

기본적으로 Linux 패키지 설치는 다음 사용자 및 그룹이 있어야 합니다:

| Linux 사용자 및 그룹 | 필수                                | 설명                                                           | 기본 홈 디렉터리       | 기본 셸 |
|----------------------|-----------------------------------------|-----------------------------------------------------------------------|------------------------------|---------------|
| `git`                | 예                                     | GitLab 사용자/그룹                                                     | `/var/opt/gitlab`            | `/bin/sh`     |
| `gitlab-www`         | 예                                     | 웹 서버 사용자/그룹                                                 | `/var/opt/gitlab/nginx`      | `/bin/false`  |
| `gitlab-prometheus`  | 예                                     | Prometheus 모니터링 및 다양한 내보내기의 Prometheus 사용자/그룹 | `/var/opt/gitlab/prometheus` | `/bin/sh`     |
| `gitlab-redis`       | 패키지된 Redis를 사용할 때만      | GitLab의 Redis 사용자/그룹                                           | `/var/opt/gitlab/redis`      | `/bin/false`  |
| `gitlab-psql`        | 패키지된 PostgreSQL을 사용할 때만 | PostgreSQL 사용자/그룹                                                 | `/var/opt/gitlab/postgresql` | `/bin/sh`     |
| `gitlab-consul`      | GitLab Consul을 사용할 때만           | GitLab Consul 사용자/그룹                                              | `/var/opt/gitlab/consul`     | `/bin/sh`     |
| `registry`           | GitLab Registry를 사용할 때만         | GitLab Registry 사용자/그룹                                            | `/var/opt/gitlab/registry`   | `/bin/sh`     |
| `gitlab-backup`      | `gitlab-backup-cli`을 사용할 때만     | GitLab Backup Cli 사용자                                                | `/var/opt/gitlab/backups`    | `/bin/sh`     |

사용자 및 그룹 계정 관리를 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   manage_accounts['enable'] = false
   ```

1. 선택 사항입니다. 다른 사용자/그룹 이름을 사용할 수도 있지만 사용자/그룹 세부 정보를 지정해야 합니다:

   ```ruby
   # GitLab
   user['username'] = "git"
   user['group'] = "git"
   user['shell'] = "/bin/sh"
   user['home'] = "/var/opt/custom-gitlab"

   # Web server
   web_server['username'] = 'webserver-gitlab'
   web_server['group'] = 'webserver-gitlab'
   web_server['shell'] = '/bin/false'
   web_server['home'] = '/var/opt/gitlab/webserver'

   # Prometheus
   prometheus['username'] = 'gitlab-prometheus'
   prometheus['group'] = 'gitlab-prometheus'
   prometheus['shell'] = '/bin/sh'
   prometheus['home'] = '/var/opt/gitlab/prometheus'

   # Redis (not needed when using external Redis)
   redis['username'] = "redis-gitlab"
   redis['group'] = "redis-gitlab"
   redis['shell'] = "/bin/false"
   redis['home'] = "/var/opt/redis-gitlab"

   # Postgresql (not needed when using external Postgresql)
   postgresql['username'] = "postgres-gitlab"
   postgresql['group'] = "postgres-gitlab"
   postgresql['shell'] = "/bin/sh"
   postgresql['home'] = "/var/opt/postgres-gitlab"

   # Consul
   consul['username'] = 'gitlab-consul'
   consul['group'] = 'gitlab-consul'
   consul['dir'] = "/var/opt/gitlab/registry"

   # Registry
   registry['username'] = "registry"
   registry['group'] = "registry"
   registry['dir'] = "/var/opt/gitlab/registry"
   registry['shell'] = "/usr/sbin/nologin"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 사용자의 홈 디렉터리 이동 {#move-the-home-directory-for-a-user}

GitLab 사용자의 경우 더 나은 성능을 위해 홈 디렉터리를 로컬 디스크에 설정하고 NFS와 같은 공유 스토리지에 설정하지 않는 것이 좋습니다. NFS에서 설정할 때 Git 요청은 Git 구성을 읽기 위해 다른 네트워크 요청을 만들어야 하며 이는 Git 작업의 대기 시간을 증가시킵니다.

기존 홈 디렉터리를 이동하려면 GitLab 서비스를 중지해야 하며 일부 다운타임이 필요합니다:

1. GitLab을 중지합니다:

   ```shell
   sudo gitlab-ctl stop
   ```

1. runit 서버를 중지합니다:

   ```shell
   sudo systemctl stop gitlab-runsvdir
   ```

1. 홈 디렉터리를 변경합니다:

   ```shell
   sudo usermod -d /path/to/home <username>
   ```

   기존 데이터가 있으면 새 위치로 수동으로 복사/rsync해야 합니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   user['home'] = "/var/opt/custom-gitlab"
   ```

1. runit 서버를 시작합니다:

   ```shell
   sudo systemctl start gitlab-runsvdir
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 스토리지 디렉터리 관리 비활성화 {#disable-storage-directories-management}

Linux 패키지는 올바른 소유권과 권한을 사용하여 필요한 모든 디렉터리를 생성하고 이를 최신 상태로 유지합니다.

일부 디렉터리는 대량의 데이터를 보유하므로 특정 설정에서는 이러한 디렉터리가 NFS(또는 다른) 공유에 마운트될 가능성이 높습니다.

일부 마운트 유형은 루트 사용자(초기 설정의 기본 사용자)에 의해 디렉터리를 자동으로 생성할 수 없습니다(예: `root_squash`이 활성화된 NFS). 이를 해결하기 위해 Linux 패키지는 디렉터리의 소유자 사용자를 사용하여 해당 디렉터리를 생성하려고 시도합니다.

### `/etc/gitlab` 디렉터리 관리 비활성화 {#disable-the-etcgitlab-directory-management}

`/etc/gitlab` 디렉터리가 마운트되어 있으면 해당 디렉터리의 관리를 끌 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   manage_storage_directories['manage_etc'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### `/var/opt/gitlab` 디렉터리 관리 비활성화 {#disable-the-varoptgitlab-directory-management}

모든 GitLab 스토리지 디렉터리를 마운트하고 각각 별도의 마운트를 수행하는 경우 스토리지 디렉터리의 관리를 완전히 비활성화해야 합니다.

Linux 패키지 설치는 이러한 디렉터리가 파일 시스템에 존재해야 합니다. 이 설정이 설정된 경우 올바른 권한을 생성하고 설정하는 것은 귀사의 책임입니다.

이 설정을 활성화하면 다음 디렉터리의 생성을 방지합니다:

| 기본 위치                                       | 권한 | 소유권        | 목적 |
|--------------------------------------------------------|-------------|------------------|---------|
| `/var/opt/gitlab/git-data`                             | `2770`      | `git:git`        | 리포지토리 디렉터리 보유 |
| `/var/opt/gitlab/git-data/repositories`                | `2770`      | `git:git`        | Git 리포지토리 보유 |
| `/var/opt/gitlab/gitlab-rails/shared`                  | `0751`      | `git:gitlab-www` | 대용량 객체 디렉터리 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/artifacts`        | `0700`      | `git:git`        | CI 아티팩트 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/external-diffs`   | `0700`      | `git:git`        | 외부 머지 리퀘스트 차이점 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/lfs-objects`      | `0700`      | `git:git`        | LFS 객체 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/packages`         | `0700`      | `git:git`        | 패키지 리포지토리 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy` | `0700`      | `git:git`        | 종속성 프록시 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/terraform_state`  | `0700`      | `git:git`        | 테라폼 상태 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`  | `0700`      | `git:git`        | 업로드된 보안 파일 보유 |
| `/var/opt/gitlab/gitlab-rails/shared/pages`            | `0750`      | `git:gitlab-www` | 사용자 페이지 보유 |
| `/var/opt/gitlab/gitlab-rails/uploads`                 | `0700`      | `git:git`        | 사용자 첨부 파일 보유 |
| `/var/opt/gitlab/gitlab-ci/builds`                     | `0700`      | `git:git`        | CI 빌드 로그 보유 |
| `/var/opt/gitlab/.ssh`                                 | `0700`      | `git:git`        | 인증된 키 보유 |

스토리지 디렉터리의 관리를 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   manage_storage_directories['enable'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 특정 파일 시스템이 마운트된 후에만 Linux 패키지 설치 서비스 시작 {#start-linux-package-installation-services-only-after-a-given-file-system-is-mounted}

특정 파일 시스템이 마운트되기 전에 Linux 패키지 설치 서비스(NGINX, Redis, Puma 등)가 시작되는 것을 방지하려면 `high_availability['mountpoint']` 설정을 설정할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # wait for /var/opt/gitlab to be mounted
   high_availability['mountpoint'] = '/var/opt/gitlab'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   > [!note]
   > 마운트 지점이 없으면 GitLab이 재구성을 실패합니다.

## 런타임 디렉터리 구성 {#configure-the-runtime-directory}

Prometheus 모니터링이 활성화되면 GitLab Exporter는 각 Puma 프로세스(Rails 메트릭)의 측정을 수행합니다. 모든 Puma 프로세스는 각 컨트롤러 요청에 대해 메트릭 파일을 임시 위치에 작성해야 합니다. 그 후 Prometheus는 이 모든 파일을 수집하고 해당 값을 처리합니다.

디스크 I/O 생성을 피하기 위해 Linux 패키지는 런타임 디렉터리를 사용합니다.

`reconfigure` 중에 패키지는 `/run`이 `tmpfs` 마운트인지 확인합니다. 그렇지 않으면 다음 경고가 표시되고 Rails 메트릭이 비활성화됩니다:

```plaintext
Runtime directory '/run' is not a tmpfs mount.
```

Rails 메트릭을 다시 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하여 `tmpfs` 마운트를 생성합니다(구성에 `=`이 없음을 참고하세요):

   ```ruby
   runtime_dir '/path/to/tmpfs'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 실패한 인증 금지 구성 {#configure-a-failed-authentication-ban}

Git 및 컨테이너 레지스트리에 대해 [실패한 인증 금지](https://docs.gitlab.com/security/rate_limits/#failed-authentication-ban-for-git-and-container-registry)를 구성할 수 있습니다. 클라이언트가 금지되면 403 오류 코드가 반환됩니다.

다음 설정을 구성할 수 있습니다:

| 설정        | 설명 |
|----------------|-------------|
| `enabled`      | `false` 기본값. Git 및 컨테이너 레지스트리 인증 금지를 활성화하려면 이를 `true`로 설정합니다. |
| `ip_whitelist` | 차단하지 않을 IP입니다. Ruby 배열에서 문자열로 포맷해야 합니다. 단일 IP 또는 CIDR 표기법(예: `["127.0.0.1", "127.0.0.2", "127.0.0.3", "192.168.0.1/24"]`)을 사용할 수 있습니다. |
| `maxretry`     | 지정된 시간에 요청을 수행할 수 있는 최대 횟수입니다. |
| `findtime`     | IP가 거부 목록에 추가되기 전에 실패한 요청이 IP에 대해 계산될 수 있는 최대 시간(초 단위)입니다. |
| `bantime`      | IP가 차단되는 총 시간(초 단위)입니다. |

Git 및 컨테이너 레지스트리 인증 금지를 구성하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['rack_attack_git_basic_auth'] = {
     'enabled' => true,
     'ip_whitelist' => ["127.0.0.1"],
     'maxretry' => 10, # Limit the number of Git HTTP authentication attempts per IP
     'findtime' => 60, # Reset the auth attempt counter per IP after 60 seconds
     'bantime' => 3600 # Ban an IP for one hour (3600s) after too many auth attempts
   }
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 설치 중 자동 캐시 정리 비활성화 {#disable-automatic-cache-cleaning-during-installation}

대규모 GitLab 설치가 있는 경우 `rake cache:clear` 작업 실행을 원하지 않을 수 있습니다. 완료하는 데 시간이 오래 걸릴 수 있기 때문입니다. 기본적으로 캐시 정리 작업은 재구성 중에 자동으로 실행됩니다.

설치 중 자동 캐시 정리를 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # This is an advanced feature used by large gitlab deployments where loading
   # whole RAILS env takes a lot of time.
   gitlab_rails['rake_cache_clear'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Sentry를 사용한 오류 보고 및 로깅 {#error-reporting-and-logging-with-sentry}

> [!warning]
> GitLab 17.0 이상에서는 Sentry 버전 21.5.0 이상만 지원됩니다. 호스트하는 Sentry 인스턴스의 이전 버전을 사용하는 경우 GitLab 환경에서 계속 오류를 수집하려면 [Sentry를 업그레이드](https://develop.sentry.dev/self-hosted/releases/)해야 합니다.

Sentry는 SaaS(<https://sentry.io/welcome/>)로 사용하거나 [직접 호스트](https://develop.sentry.dev/self-hosted/)할 수 있는 오픈 소스 오류 보고 및 로깅 도구입니다.

Sentry를 구성하려면:

1. Sentry에서 프로젝트를 생성합니다.
1. 생성한 프로젝트의 [데이터 소스 이름(DSN)](https://docs.sentry.io/concepts/key-terms/dsn-explainer/)을 찾습니다.
1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['sentry_enabled'] = true
   gitlab_rails['sentry_dsn'] = 'https://<public_key>@<host>/<project_id>'            # value used by the Rails SDK
   gitlab_rails['sentry_clientside_dsn'] = 'https://<public_key>@<host>/<project_id>' # value used by the Browser JavaScript SDK
   gitlab_rails['sentry_environment'] = 'production'
   ```

   [Sentry 환경](https://docs.sentry.io/concepts/key-terms/environments/)을 사용하여 여러 배포된 GitLab 환경(예: lab, 개발, 스테이징 및 프로덕션)에서 오류 및 이슈를 추적할 수 있습니다.

1. 선택 사항입니다. 특정 서버에서 보낸 모든 이벤트에 사용자 정의 [Sentry 태그](https://docs.sentry.io/concepts/key-terms/enrich-data/)를 설정하려면 `GITLAB_SENTRY_EXTRA_TAGS` 환경 변수를 설정할 수 있습니다. 이 변수는 해당 서버의 모든 예외에 대해 Sentry에 전달해야 하는 모든 태그를 나타내는 JSON으로 인코딩된 해시입니다.

   예를 들어 다음을 설정합니다:

   ```ruby
   gitlab_rails['env'] = {
     'GITLAB_SENTRY_EXTRA_TAGS' => '{"stage": "main"}'
   }
   ```

   `main` 값으로 `stage` 태그를 추가합니다.

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 콘텐츠 배달 네트워크 URL 설정 {#set-a-content-delivery-network-url}

`gitlab_rails['cdn_host']`을 사용하여 콘텐츠 배달 네트워크(CDN) 또는 자산 호스트로 정적 자산을 제공합니다. 이는 [Rails 자산 호스트](https://guides.rubyonrails.org/configuring.html#config-asset-host)를 구성합니다.

CDN/자산 호스트를 설정하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['cdn_host'] = 'https://mycdnsubdomain.fictional-cdn.com'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

자산 호스트로 작동하도록 일반 서비스를 구성하기 위한 추가 설명서는 [이 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5708)에서 추적됩니다.

## 콘텐츠 보안 정책 설정 {#set-a-content-security-policy}

CSP(콘텐츠 보안 정책)를 설정하면 JavaScript XSS(교차 사이트 스크립팅) 공격을 방지할 수 있습니다. 자세한 내용은 [CSP에 대한 Mozilla 설명서](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP)를 참조하세요.

[인라인 JavaScript와 함께 CSP 및 nonce-source](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/script-src)은 GitLab.com에서 사용할 수 있습니다. [기본적으로 구성되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/30720)은 GitLab Self-Managed에 있습니다.

> [!note]
> CSP 규칙을 잘못 구성하면 GitLab이 제대로 작동하지 않을 수 있습니다. 정책을 롤아웃하기 전에 `report_only`을 `true`로 변경하여 구성을 테스트할 수도 있습니다.

CSP를 추가하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false
   }
   ```

   GitLab은 CSP에 대한 안전한 기본값을 자동으로 제공합니다. 지시문에 대해 `<default_value>` 값을 명시적으로 설정하는 것은 값을 설정하지 않는 것과 동일하며 기본값을 사용합니다.

   사용자 정의 CSP를 추가하려면:

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false,
       directives: {
         default_src: "'none'",
         script_src: "https://example.com"
       }
   }
   ```

   명시적으로 구성되지 않은 지시문에는 안전한 기본값이 사용됩니다.

   CSP 지시문을 설정 해제하려면 `false` 값을 설정합니다.

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 호스트 헤더 공격을 방지하기 위해 허용된 호스트 설정 {#set-allowed-hosts-to-prevent-host-header-attacks}

GitLab이 의도된 것 이외의 호스트 헤더를 수락하지 않도록 하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['allowed_hosts'] = ['gitlab.example.com']
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`allowed_hosts`을 구성하지 않은 경우로 인한 알려진 보안 이슈는 없지만 잠재적인 [HTTP 호스트 헤더 공격](https://portswigger.net/web-security/host-header)에 대한 방어심화를 위해 권장됩니다.

Apache와 같은 사용자 정의 외부 프록시를 사용하는 경우 로컬호스트 주소 또는 이름(`localhost` 또는 `127.0.0.1`)을 추가해야 할 수 있습니다. 프록시를 통해 workhorse로 전달되는 잠재적인 HTTP 호스트 헤더 공격을 완화하기 위해 외부 프록시에 필터를 추가해야 합니다.

```ruby
gitlab_rails['allowed_hosts'] = ['gitlab.example.com', '127.0.0.1', 'localhost']
```

## 세션 쿠키 구성 {#session-cookie-configuration}

생성된 웹 세션 쿠키 값의 접두사를 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab_rails['session_store_session_cookie_token_prefix'] = 'custom_prefix_'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

기본값은 빈 문자열 `""`입니다.

## 순수 텍스트 저장소 없이 구성 요소에 민감한 구성 제공 {#provide-sensitive-configuration-to-components-without-plain-text-storage}

일부 구성 요소는 `gitlab.rb`에서 `extra_config_command` 옵션을 노출합니다. 이는 외부 스크립트가 순수 텍스트 저장소에서 읽는 대신 동적으로 암호를 제공할 수 있습니다.

사용 가능한 옵션은 다음과 같습니다:

| `gitlab.rb` 설정                          | 책임 |
|----------------------------------------------|----------------|
| `redis['extra_config_command']`              | Redis 서버 구성 파일에 대한 추가 구성을 제공합니다. |
| `gitlab_rails['redis_extra_config_command']` | GitLab Rails 애플리케이션에서 사용하는 Redis 구성 파일에 추가 구성을 제공합니다. (`resque.yml`, `redis.yml`, `redis.<redis_instance>.yml` 파일) |
| `gitlab_rails['db_extra_config_command']`    | GitLab Rails 애플리케이션에서 사용하는 DB 구성 파일에 대한 추가 구성을 제공합니다. (`database.yml`) |
| `gitlab_kas['extra_config_command']`         | GitLab 에이전트 서버(KAS) for Kubernetes에 추가 구성을 제공합니다. |
| `gitlab_workhorse['extra_config_command']`   | GitLab Workhorse에 대한 추가 구성을 제공합니다. |
| `gitlab_exporter['extra_config_command']`    | GitLab Exporter에 대한 추가 구성을 제공합니다. |

이 옵션 중 하나에 할당된 값은 STDOUT에 필수 형식으로 민감한 구성을 쓰는 실행 가능한 스크립트의 절대 경로여야 합니다. 구성 요소:

1. 제공된 스크립트를 실행합니다.
1. 스크립트에서 내보낸 사용자 및 기본 구성 파일로 설정된 값을 바꿉니다.

### Redis 서버 및 클라이언트 구성 요소에 Redis 암호 제공 {#provide-redis-password-to-redis-server-and-client-components}

예를 들어 아래 스크립트 및 `gitlab.rb` 스니펫을 사용하여 Redis 서버에 대한 암호 및 Redis에 연결해야 하는 구성 요소를 지정할 수 있습니다.

> [!note]
> Redis 서버에 암호를 지정할 때 이 방법은 `gitlab.rb` 파일에서 순수 텍스트 암호를 갖는 것에서만 사용자를 절약합니다. 암호는 `/var/opt/gitlab/redis/redis.conf`에 있는 Redis 서버 구성 파일에서 순수 텍스트로 끝납니다.

1. 아래 스크립트를 `/opt/generate-redis-conf`로 저장합니다

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'json'
   require 'yaml'

   class RedisConfig
     REDIS_PASSWORD = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch Redis password

     class << self
       def server
         puts "requirepass '#{REDIS_PASSWORD}'"
         puts "masterauth '#{REDIS_PASSWORD}'"
       end

       def rails
         puts YAML.dump({
           'password' => REDIS_PASSWORD
         })
       end

       def kas
         puts YAML.dump({
           'redis' => {
             'password' => REDIS_PASSWORD
           }
         })
       end

       def workhorse
         puts JSON.dump({
           redis: {
             password: REDIS_PASSWORD
           }
         })
       end

       def gitlab_exporter
         puts YAML.dump({
           'probes' => {
             'sidekiq' => {
               'opts' => {
                 'redis_password' => REDIS_PASSWORD
               }
             }
           }
         })
       end
     end
   end

   def print_error_and_exit
     $stdout.puts "Usage: generate-redis-conf <COMPONENT>"
     $stderr.puts "Supported components are: server, rails, kas, workhorse, gitlab_exporter"

     exit 1
   end

   print_error_and_exit if ARGV.length != 1

   component = ARGV.shift
   begin
     RedisConfig.send(component.to_sym)
   rescue NoMethodError
     print_error_and_exit
   end
   ```

1. 위에서 생성한 스크립트가 실행 가능한지 확인합니다:

   ```shell
   chmod +x /opt/generate-redis-conf
   ```

1. 아래 스니펫을 `/etc/gitlab/gitlab.rb`에 추가합니다:

   ```ruby
   redis['extra_config_command'] = '/opt/generate-redis-conf server'

   gitlab_rails['redis_extra_config_command'] = '/opt/generate-redis-conf rails'
   gitlab_workhorse['extra_config_command'] = '/opt/generate-redis-conf workhorse'
   gitlab_kas['extra_config_command'] = '/opt/generate-redis-conf kas'
   gitlab_exporter['extra_config_command'] = '/opt/generate-redis-conf gitlab_exporter'
   ```

1. `sudo gitlab-ctl reconfigure`을(를) 실행합니다.

### GitLab Rails에 PostgreSQL 사용자 암호 제공 {#provide-the-postgresql-user-password-to-gitlab-rails}

예를 들어 아래 스크립트 및 구성을 사용하여 GitLab Rails이 PostgreSQL 서버에 연결할 때 사용해야 하는 암호를 제공할 수 있습니다.

1. 아래 스크립트를 `/opt/generate-db-config`로 저장합니다:

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'yaml'

   db_password = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch DB password

   puts YAML.dump({
    'main' => {
      'password' => db_password
    },
    'ci' => {
      'password' => db_password
    }
   })
   ```

1. 위에서 생성한 스크립트가 실행 가능한지 확인합니다:

   ```shell
   chmod +x /opt/generate-db-config
   ```

1. 아래 스니펫을 `/etc/gitlab/gitlab.rb`에 추가합니다:

   ```ruby
   gitlab_rails['db_extra_config_command'] = '/opt/generate-db-config'
   ```

1. `sudo gitlab-ctl reconfigure`을(를) 실행합니다.

## 관련 항목 {#related-topics}

- [가장을 사용하지 않도록 설정](https://docs.gitlab.com/api/rest/authentication/#disable-impersonation)
- [LDAP 로그인 설정](https://docs.gitlab.com/administration/auth/ldap/)
- [스마트카드 인증](https://docs.gitlab.com/administration/auth/smartcard/)
- [NGINX 설정](nginx.md) 다음과 같은 사항:
  - HTTPS 설정
  - `HTTP` 요청을 `HTTPS`로 리디렉션
  - 기본 포트 및 SSL 인증서 위치 변경
  - NGINX 수신 대기 주소 또는 주소 설정
  - GitLab 서버 블록에 사용자 정의 NGINX 설정 삽입
  - NGINX 구성에 사용자 정의 설정 삽입
  - `nginx_status` 활성화
- [패키지되지 않은 웹 서버 사용](nginx.md#use-a-non-bundled-web-server)
- [패키지되지 않은 PostgreSQL 데이터베이스 관리 서버 사용](database.md)
- [패키지되지 않은 Redis 인스턴스 사용](redis.md)
- [`ENV` 변수를 GitLab 런타임 환경에 추가](environment-variables.md)
- [`gitlab.yml` 및 `application.yml` 설정 변경](gitlab.yml.md)
- [SMTP를 통해 애플리케이션 이메일 보내기](smtp.md)
- [OmniAuth 설정(Google, Twitter, GitHub 로그인)](https://docs.gitlab.com/integration/omniauth/)
- [Puma 설정 조정](https://docs.gitlab.com/administration/operations/puma/)

## 문제 해결 {#troubleshooting}

### 상대 URL 문제 해결 {#relative-url-troubleshooting}

상대 URL 구성으로 이동한 후 GitLab 자산이 손상되는 이슈(누락된 이미지 또는 응답하지 않는 구성 요소 등)를 발견하면 `Frontend` 레이블로 [GitLab](https://gitlab.com/gitlab-org/gitlab)에 이슈를 제출하세요.

### 오류: `Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group]` {#error-mixlibshelloutshellcommandfailed-linux_usergitlab-user-and-group}

[사용자의 홈 디렉터리 이동](#move-the-home-directory-for-a-user) 시 runit 서비스가 중지되지 않고 사용자의 홈 디렉터리가 수동으로 이동되지 않으면 GitLab은 재구성 중에 오류가 발생합니다:

```plaintext
account[GitLab user and group] (package::users line 28) had an error: Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/package/resources/account.rb line 51) had an error: Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '8'
---- Begin output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
STDOUT:
STDERR: usermod: user git is currently used by process 1234
---- End output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
Ran ["usermod", "-d", "/var/opt/gitlab", "git"] returned 8
```

홈 디렉터리를 이동하기 전에 `runit`을 중지해야 합니다.

### Git 사용자 또는 그룹의 이름을 변경한 후 GitLab이 502로 응답 {#gitlab-responds-with-502-after-changing-the-name-of-the-git-user-or-group}

기존 설치에서 [Git 사용자 또는 그룹의 이름](#change-the-name-of-the-git-user-or-group)을 변경하면 많은 부작용이 발생할 수 있습니다.

파일에 액세스할 수 없는 것과 관련된 오류를 확인하고 권한을 수정할 수 있습니다:

```shell
gitlab gitlab-ctl tail -f
```
