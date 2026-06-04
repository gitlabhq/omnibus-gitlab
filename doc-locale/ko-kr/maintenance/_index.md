---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 유지보수 명령
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 명령은 설치 후 실행할 수 있습니다.

## 서비스 상태 확인 {#get-service-status}

`sudo gitlab-ctl status`을(를) 실행하여 각 GitLab 구성 요소의 현재 상태 및 작동 시간을 확인합니다.

출력은 다음과 같이 표시됩니다:

```plaintext
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: puma: (pid 961) 7s; run: log: (pid 960) 7s
```

예시로, 이전 예제의 첫 번째 줄은 다음과 같이 해석할 수 있습니다:

- `Nginx`은(는) 프로세스 이름입니다.
- `972`은(는) 프로세스 식별자입니다.
- NGINX는 7초(`7s`) 동안 실행 중입니다.
- `log`은(는) 선행 프로세스에 연결된 [svlogd 로깅 프로세스](https://manpages.ubuntu.com/manpages/noble/en/man8/svlogd.8.html)를 나타냅니다.
- `971`은(는) 로깅 프로세스의 프로세스 식별자입니다.
- 로깅 프로세스는 7초(`7s`) 동안 실행 중입니다.

## 구성 표시 {#show-configuration}

`sudo gitlab-ctl show-config`을(를) 실행하여 `gitlab-ctl reconfigure`에서 생성될 구성을 표시합니다. 출력은 JSON 형식이며 다음과 같이 표시됩니다:

```json
{
  "gitlab": {
    "gitlab_sshd": {

    },
    "gitlab_shell": {
      "secret_token": "<SECRET_TOKEN>",
      "auth_file": "/var/opt/gitlab/.ssh/authorized_keys"
    },
    "gitlab_rails": {
      "smtp_address": "smtp.example.com",
      "smtp_port": 587,
      "smtp_user_name": "user@example.com",
      "smtp_password": "<SMTP_PASSWORD>",
      "smtp_domain": "smtp.example.com",
      "smtp_authentication": "login",
      "monitoring_whitelist": [
        "127.0.0.0/8",
        "::1/128",
      ],
   ...
    }
  }
}
```

GitLab을 다시 구성한 후 `/var/opt/gitlab` 디렉토리 아래의 해당 서비스에 대한 자동 생성된 YAML 구성 파일을 보고 최신 적용된 구성을 확인할 수 있습니다. 위의 예제에서 `gitlab-rails`에 대한 구성을 `/var/opt/gitlab/gitlab-rails/etc/gitlab.yml` 아래에서 확인할 수 있습니다.

## 프로세스 로그 추적 {#tail-process-logs}

[Linux 패키지 설치의 로그](../settings/logs.md)를 참조하세요.

## 시작 및 중지 {#starting-and-stopping}

Linux 패키지를 설치하고 구성한 후 서버에는 `/etc/inittab` 또는 `/etc/init/gitlab-runsvdir.conf` Upstart 리소스를 통해 부팅 시 시작되는 runit 서비스 디렉토리(`runsvdir`) 프로세스가 실행 중입니다. `runsvdir` 프로세스를 직접 처리할 필요가 없으며, 대신 `gitlab-ctl` 프론트엔드를 사용할 수 있습니다.

다음 명령으로 GitLab 및 모든 구성 요소를 시작, 중지 또는 다시 시작할 수 있습니다.

```shell
# Start all GitLab components
sudo gitlab-ctl start

# Stop all GitLab components
sudo gitlab-ctl stop

# Restart all GitLab components
sudo gitlab-ctl restart

# Restart all GitLab components except given services ... (e.g. gitaly, redis)
sudo gitlab-ctl restart-except gitaly redis
```

단일 코어 서버에서는 Puma 및 Sidekiq을 다시 시작하는 데 최대 1분이 소요될 수 있습니다. GitLab 인스턴스는 Puma가 다시 실행될 때까지 502 오류를 표시합니다.

개별 구성 요소를 시작, 중지 또는 다시 시작할 수도 있습니다.

```shell
sudo gitlab-ctl restart sidekiq
```

Puma는 거의 무중단 재로드를 지원합니다. 다음과 같이 트리거할 수 있습니다:

```shell
sudo gitlab-ctl hup puma
```

`hup` 명령이 완료될 때까지 기다려야 합니다. 이는 시간이 걸릴 수 있습니다. 노드를 풀에서 제외하고 이 명령이 완료될 때까지 해당 노드에서 서비스를 다시 시작하지 마세요. Puma 재로드를 사용하여 Ruby 런타임을 업데이트할 수는 없습니다.

Puma에는 애플리케이션 동작을 제어하는 다음 신호가 있습니다:

| 신호   | Puma                                                                |
| -------- | ------                                                              |
| `HUP`    | 정의된 로그 파일을 다시 열거나 프로세스를 중지하여 강제로 다시 시작      |
| `INT`    | 요청 처리를 정상적으로 중지                                |
| `USR1`   | 단계별로 워커를 다시 시작(롤링 재시작), 구성 재로드 없음 |
| `USR2`   | 워커를 다시 시작하고 구성 재로드                                   |
| `QUIT`   | 주 프로세스 종료                                               |

Puma의 경우 `gitlab-ctl hup puma`은(는) `SIGINT` 및 `SIGTERM` (프로세스가 다시 시작되지 않으면) 신호 시퀀스를 보냅니다. Puma는 `SIGINT`을(를) 받는 즉시 새 연결을 수락하지 않습니다. 실행 중인 모든 요청을 완료합니다. 그 후 `runit`이(가) 서비스를 다시 시작합니다.

## Rake 작업 호출 {#invoking-rake-tasks}

GitLab Rake 작업을 호출하려면 `gitlab-rake`을(를) 사용합니다. 예를 들어:

```shell
sudo gitlab-rake gitlab:check
```

`git` 사용자인 경우 `sudo`을(를) 생략합니다.

기존 GitLab 설치와 달리 사용자 또는 `RAILS_ENV` 환경 변수를 변경할 필요가 없습니다. 이는 `gitlab-rake` 래퍼 스크립트에서 처리됩니다.

## Rails 콘솔 세션 시작 {#starting-a-rails-console-session}

자세한 내용은 [Rails 콘솔](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session)을(를) 참조하세요.

## PostgreSQL 슈퍼유저 `psql` 세션 시작 {#starting-a-postgresql-superuser-psql-session}

번들로 제공되는 PostgreSQL 서비스에 대한 슈퍼유저 액세스가 필요한 경우 `gitlab-psql` 명령을 사용할 수 있습니다. 일반 `psql` 명령과 동일한 인수를 사용합니다.

```shell
# Superuser psql access to GitLab's database
sudo gitlab-psql -d gitlabhq_production
```

`gitlab-ctl reconfigure`을(를) 최소한 한 번 실행한 후에만 작동합니다. `gitlab-psql` 명령은 원격 PostgreSQL 서버에 연결하거나 로컬 비 Linux 패키지 PostgreSQL 서버에 연결하는 데 사용할 수 없습니다.

### Geo 추적 데이터베이스에서 PostgreSQL 슈퍼유저 `psql` 세션 시작 {#starting-a-postgresql-superuser-psql-session-in-geo-tracking-database}

이전 명령과 유사하게, 번들로 제공되는 Geo 추적 데이터베이스(`geo-postgresql`)에 대한 슈퍼유저 액세스가 필요한 경우 `gitlab-geo-psql`을(를) 사용할 수 있습니다. 일반 `psql` 명령과 동일한 인수를 사용합니다. HA의 경우 [구성 확인](https://docs.gitlab.com/administration/geo/replication/multiple_servers/)에서 필요한 인수에 대해 자세히 알아보세요.

```shell
# Superuser psql access to GitLab's Geo tracking database
sudo gitlab-geo-psql -d gitlabhq_geo_production
```

## 컨테이너 레지스트리 가비지 컬렉션 {#container-registry-garbage-collection}

컨테이너 레지스트리는 상당한 양의 디스크 공간을 사용할 수 있습니다. 사용하지 않은 레이어를 정리하기 위해 레지스트리에는 [가비지 컬렉션 명령](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-garbage-collection)이(가) 포함되어 있습니다.

## GitLab에 로그인하지 못하도록 사용자 제한 {#restrict-users-from-logging-into-gitlab}

일시적으로 사용자가 GitLab에 로그인하지 못하도록 제한해야 하는 경우 `sudo gitlab-ctl deploy-page up`을(를) 사용할 수 있습니다. 사용자가 GitLab URL로 이동하면 임의의 `Deploy in progress` 페이지가 표시됩니다.

페이지를 제거하려면 `sudo gitlab-ctl deploy-page down`을(를) 실행하면 됩니다. `sudo gitlab-ctl deploy-page status`으로 배포 페이지의 상태를 확인할 수도 있습니다.

참고로, GitLab에 로그인을 제한하고 프로젝트 변경을 제한하려면 [프로젝트를 읽기 전용으로 설정](https://docs.gitlab.com/administration/read_only_gitlab/#make-the-repositories-read-only)한 다음 `Deploy in progress` 페이지를 표시할 수 있습니다.

## 비밀 파일 회전 {#rotate-the-secrets-file}

보안상 필요한 경우 `/etc/gitlab/gitlab-secrets.json` 비밀 파일을 회전할 수 있습니다. 이 파일에서:

- `gitlab_rails` 비밀을 회전하지 마세요. 데이터베이스 암호화 키가 포함되어 있기 때문입니다. 이 비밀이 회전되면 [비밀 파일이 손실된 경우](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost)와 동일한 동작이 표시됩니다.
- 다른 모든 비밀을 회전할 수 있습니다.

GitLab 환경에 여러 노드가 있는 경우 Rails 노드 중 하나를 선택하여 초기 단계를 수행합니다.

비밀을 회전하려면:

1. [데이터베이스 값을 해독할 수 있는지 확인](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets)하고 표시된 암호 해독 오류를 메모하거나 진행하기 전에 해결합니다.

1. 권장. `gitlab_rails`에 대한 현재 비밀을 추출합니다. 나중에 필요하므로 출력을 저장합니다:

   ```shell
   sudo grep "secret_key_base\|db_key_base\|otp_key_base\|encrypted_settings_key_base\|openid_connect_signing_key\|active_record_encryption_primary_key\|active_record_encryption_deterministic_key\|active_record_encryption_key_derivation_salt" /etc/gitlab/gitlab-secrets.json
   ```

1. 현재 비밀 파일을 다른 위치로 이동합니다:

   ```shell
   sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
   ```

1. [GitLab 다시 구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)합니다. GitLab이 새 비밀 값으로 새 `/etc/gitlab/gitlab-secrets.json` 파일을 생성합니다.

1. `gitlab_rails`에 대한 이전 비밀을 추출한 경우 새 `/etc/gitlab/gitlab-secrets.json` 파일을 편집하고 `gitlab_rails` 아래의 키/값 쌍을 이전에 얻은 이전 비밀 출력으로 바꿉니다.

1. [GitLab 다시 구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)하여 비밀 파일에 대한 변경 사항을 적용합니다.

1. [GitLab 다시 시작](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation)하여 모든 서비스가 새 비밀을 사용하도록 합니다.

1. GitLab 환경에 여러 노드가 있는 경우 모든 다른 노드에 비밀을 복사해야 합니다:

   1. 다른 모든 노드에서 현재 비밀 파일을 다른 위치로 이동합니다:

      ```shell
      sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
      ```

   1. Rails 노드에서 새 `/etc/gitlab/gitlab-secrets.json` 파일을 모든 다른 GitLab 노드로 복사합니다.

   1. 다른 모든 노드에서 각 노드에 대해 [GitLab 다시 구성](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)합니다.

   1. 다른 모든 노드에서 각 노드에 대해 [GitLab 다시 시작](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation)하여 모든 서비스가 새 비밀을 사용하도록 합니다.

   1. 모든 노드에서 `/etc/gitlab/gitlab-secrets.json` 파일의 체크섬 일치를 실행하여 비밀이 일치하는지 확인합니다:

      ```shell
      sudo md5sum /etc/gitlab/gitlab-secrets.json
      ```

1. [데이터베이스 값을 해독할 수 있는지 확인](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets)합니다. 출력은 이전 실행과 일치해야 합니다.
1. GitLab이 예상대로 작동하는지 확인합니다. 작동하면 이전 비밀을 삭제하는 것이 안전해야 합니다.

## `gitlab-ctl`에 대해 bash 완료 활성화 {#enable-bash-completion-for-gitlab-ctl}

Linux 패키지에는 `gitlab-ctl` 명령에 대한 bash 완료 스크립트가 포함되어 있습니다. 활성화하려면 쉘 구성 파일에서 완료 스크립트를 원본으로 지정합니다.

완료 스크립트는 `/opt/gitlab/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion`에 있습니다.

bash 완료를 활성화하려면:

1. 쉘 구성 파일(`.bashrc`, `.bash_profile`, 또는 동등한)에 다음 줄을 추가합니다:

   ```shell
   source /opt/gitlab/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion
   ```

1. 쉘 구성을 다시 로드합니다:

   ```shell
   source ~/.bashrc
   ```

활성화한 후 `gitlab-ctl` 명령으로 탭 완료를 사용할 수 있습니다:

```shell
gitlab-ctl <TAB>
```

완료 스크립트는 `bash-completion` 패키지가 시스템에 설치되어 있어야 합니다. 설치되지 않은 경우 시스템의 패키지 관리자를 사용하여 설치할 수 있습니다:

- Debian/Ubuntu: `sudo apt-get install bash-completion`
- RHEL/CentOS: `sudo yum install bash-completion`

## 지원 중단 {#deprecations}

`sudo gitlab-ctl check-config`을(를) 실행하여 향후 GitLab 버전에서 제거할 플래그에 대해 Omnibus 구성을 확인합니다.

명령은 다음 인수를 지원합니다:

- `--version <Version>`: 확인하려는 대상 GitLab 버전.
- `--no-fail`: 지원 중단/제거가 발견되어도 오류 코드로 종료하지 않습니다.

GitLab을 업그레이드할 때 이 구성 확인이 자동으로 실행됩니다. 업그레이드 중에 이 확인을 건너뛰려면 `/etc/gitlab/skip-fail-config-check`에서 파일을 만듭니다.
