---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 자체 컴파일된 설치를 Linux 패키지 설치로 변환
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

자체 컴파일된 설치 방법을 사용하여 GitLab을 설치한 경우 인스턴스를 Linux 패키지 인스턴스로 변환할 수 있습니다.

자체 컴파일된 설치를 변환할 때:

- GitLab의 정확히 같은 버전으로 변환해야 합니다.
- [`/etc/gitlab/gitlab.rb`에서 설정을 구성](../settings/configuration.md)해야 합니다. `gitlab.yml`, `puma.rb` 및 `smtp_settings.rb`와 같은 파일의 설정은 손실됩니다.

> [!warning]
> 자체 컴파일된 설치에서의 변환은 GitLab에서 테스트되지 않았습니다.

자체 컴파일된 설치를 Linux 패키지 설치로 변환하려면:

1. 현재 자체 컴파일된 설치에서 백업을 만듭니다:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
   ```

1. [Linux 패키지를 사용하여 GitLab 설치](https://about.gitlab.com/install/)합니다.
1. 백업 파일을 새 서버의 `/var/opt/gitlab/backups/` 디렉터리로 복사합니다.
1. 새 설치에서 백업을 복원합니다([자세한 지침](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)):

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=<FILE_NAME>
   ```

   복원은 데이터베이스와 Git 데이터의 크기에 따라 몇 분 정도 걸립니다.

1. Linux 패키지 설치에서 모든 설정이 `/etc/gitlab/gitlab.rb`에 저장되므로 새 설치를 다시 구성해야 합니다. 개별 설정을 `gitlab.yml`, `puma.rb` 및 `smtp_settings.rb`와 같은 자체 컴파일된 설치 파일에서 수동으로 이동해야 합니다. 사용 가능한 모든 옵션은 [`gitlab.rb` 템플릿](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)을 참조하세요.
1. 이전 자체 컴파일된 설치에서 새 Linux 패키지 설치로 암호를 복사합니다:
   1. Rails와 관련된 암호를 복원합니다. `db_key_base`, `secret_key_base`, `otp_key_base`, `encrypted_settings_key_base`, `openid_connect_signing_key` 및 `active_record_encryption`의 값을 `/home/git/gitlab/config/secrets.yml`(자체 컴파일된 설치)에서 `/etc/gitlab/gitlab-secrets.json`(Linux 패키지 설치)의 해당 값으로 복사합니다.
   1. `/home/git/gitlab-shell/.gitlab_shell_secret`(자체 컴파일된 설치)의 내용을 `/etc/gitlab/gitlab-secrets.json`(Linux 패키지 설치)의 `secret_token`로 복사합니다. 다음과 같이 보입니다:

       ```json
       {
         "gitlab_workhorse": {
           "secret_token": "..."
         },
         "gitlab_shell": {
           "secret_token": "..."
         },
         "gitlab_rails": {
           "secret_key_base": "...",
           "db_key_base": "...",
           "otp_key_base": "...",
           "encrypted_settings_key_base": "...",
           "openid_connect_signing_key": "...",
           "active_record_encryption_primary_key": [ "..."],
           "active_record_encryption_deterministic_key": ["..."],
           "active_record_encryption_key_derivation_salt": "...",
         }
         ...
       }
       ```

1. GitLab을 다시 구성하여 변경 사항을 적용합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `/home/git/gitlab-shell/.gitlab_shell_secret`을 마이그레이션한 경우 [Gitaly를 다시 시작](https://gitlab.com/gitlab-org/gitaly/-/issues/3837)해야 합니다:

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

## 외부 PostgreSQL을 백업을 사용하여 Linux 패키지 설치로 변환 {#convert-an-external-postgresql-to-a-linux-package-installation-by-using-a-backup}

[외부 PostgreSQL 설치](https://docs.gitlab.com/administration/postgresql/external/)를 백업을 사용하여 Linux 패키지 PostgreSQL 설치로 변환할 수 있습니다. 이 작업을 수행할 때 같은 GitLab 버전을 사용해야 합니다.

외부 PostgreSQL 설치를 백업을 사용하여 Linux 패키지 PostgreSQL 설치로 변환하려면:

1. [Linux 패키지가 아닌 설치에서 백업 만들기](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)
1. [Linux 패키지 설치에서 백업 복원](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)합니다.
1. `check` 작업을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. `No such file or directory @ realpath_rec - /home/git`과 유사한 오류가 발생하면 다음을 실행합니다:

   ```shell
   find . -lname /home/git/gitlab-shell/hooks -exec sh -c 'ln -snf /opt/gitlab/embedded/service/gitlab-shell/hooks $0' {} \;
   ```

이는 `gitlab-shell`이 `/home/git`에 위치한다고 가정합니다.

## 외부 PostgreSQL을 제자리에서 Linux 패키지 설치로 변환 {#convert-an-external-postgresql-to-a-linux-package-installation-in-place}

[외부 PostgreSQL 설치](https://docs.gitlab.com/administration/postgresql/external/)를 제자리에서 Linux 패키지 PostgreSQL 설치로 변환할 수 있습니다.

이 지침은 다음을 가정합니다:

- Ubuntu에서 PostgreSQL을 사용하고 있습니다.
- 현재 GitLab 버전과 일치하는 Linux 패키지가 있습니다.
- GitLab의 자체 컴파일된 설치에서 모든 기본 경로와 사용자를 사용합니다.
- Git 사용자의 기존 홈 디렉터리(`/home/git`)가 `/var/opt/gitlab`로 변경됩니다.

외부 PostgreSQL 설치를 제자리에서 Linux 패키지 PostgreSQL 설치로 변환하려면:

1. GitLab, Redis 및 NGINX를 중지하고 비활성화합니다:

   ```shell
   # Ubuntu
   sudo service gitlab stop
   sudo update-rc.d gitlab disable

   sudo service nginx stop
   sudo update-rc.d nginx disable

   sudo service redis-server stop
   sudo update-rc.d redis-server disable
   ```

1. 구성 관리 시스템을 사용하여 서버에서 GitLab을 관리하는 경우 GitLab 및 관련 서비스를 비활성화합니다.
1. 새 설정을 위해 `gitlab.rb` 파일을 만듭니다:

   ```shell
   sudo mkdir /etc/gitlab
   sudo tee -a /etc/gitlab/gitlab.rb <<'EOF'
   # Use your own GitLab URL here
   external_url 'http://gitlab.example.com'

   # We assume your repositories are in /home/git/repositories (default for source installs) and that Gitaly
   # listens on a socket at /home/git/gitlab/tmp/sockets/private/gitaly.socket
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/home/git/repositories'
       }
     ]
   }
   gitlab_rails['repositories_storages'] = {
     default: {
       gitaly_address: '/home/git/gitlab/tmp/sockets/private/gitaly.socket'
     }
   }

   # Re-use the PostgreSQL that is already running on your system
   postgresql['enable'] = false
   # This db_host setting is for Debian PostgreSQL packages
   gitlab_rails['db_host'] = '/var/run/postgresql/'
   gitlab_rails['db_port'] = 5432
   # We assume you called the GitLab DB user 'git'
   gitlab_rails['db_username'] = 'git'
   EOF
   ```

1. 이제 Linux 패키지를 설치하고 설치를 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-ctl reconfigure` 실행이 Git 사용자의 홈 디렉터리를 변경했고 OpenSSH가 더 이상 해당 `authorized_keys` 파일을 찾을 수 없으므로 키 파일을 다시 구성합니다:

   ```shell
   sudo gitlab-rake gitlab:shell:setup
   ```

   이제 이전에 있던 리포지토리와 사용자가 있는 GitLab 서버에 HTTP 및 SSH로 액세스할 수 있습니다.

1. GitLab 웹 인터페이스에 로그인할 수 있으면 서버를 재부팅하여 이전 서비스가 Linux 패키지 설치에 방해가 되지 않도록 합니다.
1. LDAP과 같은 특수 기능을 사용하는 경우 `gitlab.rb`에 설정을 입력해야 합니다. 자세한 내용은 [설정 설명서](../settings/_index.md)를 참조하세요.
