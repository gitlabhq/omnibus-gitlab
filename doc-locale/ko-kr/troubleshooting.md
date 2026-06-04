---
stage: GitLab Delivery
group: Build, Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 설치 문제 해결
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 페이지를 사용하여 Linux 패키지 설치 시 사용자가 직면할 수 있는 일반적인 이슈를 알아보세요.

## 패키지 다운로드 시 해시 합계 불일치 {#hash-sum-mismatch-when-downloading-packages}

`apt-get install`의 출력 결과는 다음과 같습니다:

```plaintext
E: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/pool/trusty/main/g/gitlab-ce/gitlab-ce_8.1.0-ce.0_amd64.deb  Hash Sum mismatch
```

이를 해결하려면 다음을 실행하세요:

```shell
sudo rm -rf /var/lib/apt/lists/partial/*
sudo apt-get update
sudo apt-get clean
```

[CE 패키지](https://packages.gitlab.com/gitlab/gitlab-ce) 또는 [EE 패키지](https://packages.gitlab.com/gitlab/gitlab-ee) 리포지토리에서 올바른 패키지를 선택하여 패키지를 수동으로 다운로드할 수 있습니다:

```shell
curl -LJO "https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/gitlab-ce_8.1.0-ce.0_amd64.deb/download"
dpkg -i gitlab-ce_8.1.0-ce.0_amd64.deb
```

## openSUSE 및 SLES 플랫폼에서 알려지지 않은 키 서명에 대한 경고 {#installation-on-opensuse-and-sles-platforms-warns-about-unknown-key-signature}

Linux 패키지는 패키지 리포지토리가 서명된 메타데이터를 제공하는 것 외에도 [GPG 키로 서명](update/package_signatures.md)됩니다. 이것은 배포되는 패키지의 진정성과 무결성을 보장합니다. 그러나 openSUSE 및 SLES 운영 체제에서 사용되는 패키지 관리자는 때때로 이러한 서명으로 거짓 경고를 발생시킬 수 있습니다:

```plaintext
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no):
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no): yes
```

이것은 zypper이 리포지토리 구성 파일의 `gpgkey` 키워드를 무시하는 zypper의 알려진 버그입니다. 사용자는 메시지가 표시될 때 패키지 설치에 수동으로 동의해야 합니다.

따라서 openSUSE 또는 SLES 시스템에서 이러한 경고가 표시되면 설치를 계속하는 것이 안전합니다.

## apt/yum이 GPG 서명에 대해 불평합니다 {#aptyum-complains-about-gpg-signatures}

이미 GitLab 리포지토리가 구성되어 있고 `apt-get update`, `apt-get install` 또는 `yum install`을(를) 실행했으며 다음과 같은 오류가 표시되었습니다:

```plaintext
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
```

또는

```plaintext
https://packages.gitlab.com/gitlab/gitlab-ee/el/7/x86_64/repodata/repomd.xml: [Errno -1] repomd.xml signature could not be verified for gitlab-ee
```

이 오류는 일반적으로 키링에 리포지토리 메타데이터에 서명하는 데 사용되는 공개 키가 없다는 것을 의미합니다. GitLab은 apt 및 yum 리포지토리의 메타데이터에 서명하는 데 사용되는 GPG 키를 정기적으로 회전합니다. 현재 및 이전 키에 대한 자세한 내용은 [패키지 서명](update/package_signatures.md)을(를) 참조하세요. 이 오류를 해결하려면 [새 키를 가져오기 위한 단계](update/package_signatures.md#fetch-the-latest-repository-signing-key)를 따르세요.

## 재구성에서 오류 표시: `NoMethodError - undefined method '[]=' for nil:NilClass` {#reconfigure-shows-an-error-nomethoderror---undefined-method--for-nilnilclass}

`sudo gitlab-ctl reconfigure`을(를) 실행했거나 패키지 업그레이드로 인해 다음과 유사한 오류가 발생했습니다:

```plaintext
 ================================================================================
 Recipe Compile Error in /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb
 ================================================================================

NoMethodError
-------------
undefined method '[]=' for nil:NilClass

Cookbook Trace:
---------------
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/config.rb:21:in 'from_file'
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb:26:in 'from_file'

Relevant File Content:
```

이 오류는 `/etc/gitlab/gitlab.rb` 구성 파일에 잘못되었거나 지원되지 않는 구성이 포함되어 있을 때 발생합니다. 오타가 없는지 확인하거나 구성 파일에 더 이상 사용되지 않는 구성이 포함되어 있지 않은지 확인하세요.

`sudo gitlab-ctl diff-config`을(를) 사용하거나 최신 [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)을(를) 확인하여 사용 가능한 최신 구성을 확인할 수 있습니다.

## 내 브라우저에서 GitLab에 연결할 수 없습니다 {#gitlab-is-unreachable-in-my-browser}

[지정](settings/configuration.md#configure-the-external-url-for-gitlab)을(를) 시도하여 `external_url`을(를) `/etc/gitlab/gitlab.rb`에 설정하세요. 방화벽 설정도 확인하세요. GitLab 서버에서 포트 80(HTTP) 또는 443(HTTPS)이 닫혀 있을 수 있습니다.

GitLab의 `external_url` 또는 레지스트리와 같은 다른 번들 서비스를 지정하는 것은 `gitlab.rb`의 다른 부분이 따르는 `key=value` 형식을 따르지 않습니다. 다음 형식으로 설정되어 있는지 확인하세요:

```ruby
external_url "https://gitlab.example.com"
registry_external_url "https://registry.example.com"
```

> [!note]
> `external_url`과 값 사이에 등호(`=`)를 추가하지 마세요.

## 이메일이 배달되지 않습니다 {#emails-are-not-being-delivered}

이메일 배달을 테스트하기 위해 GitLab 인스턴스에서 아직 사용하지 않은 이메일의 새 GitLab 계정을 생성할 수 있습니다.

필요한 경우 `/etc/gitlab/gitlab.rb`에서 다음 설정을 사용하여 GitLab에서 보낸 이메일의 'From' 필드를 수정할 수 있습니다:

```ruby
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

`sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.

## GitLab 서비스의 TCP 포트가 이미 사용 중입니다 {#tcp-ports-for-gitlab-services-are-already-taken}

기본적으로 Puma는 TCP 주소 127.0.0.1:8080에서 수신합니다. NGINX는 모든 인터페이스에서 포트 80(HTTP) 및/또는 443(HTTPS)에서 수신합니다.

Redis, PostgreSQL 및 Puma의 포트는 `/etc/gitlab/gitlab.rb`에서 다음과 같이 재정의할 수 있습니다:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
puma['port'] = 3456
```

NGINX 포트 변경에 대해서는 [NGINX 수신 포트 설정](settings/nginx.md#set-the-nginx-listen-port)을(를) 참조하세요.

## Git 사용자에게 SSH 액세스 권한이 없습니다 {#git-user-does-not-have-ssh-access}

### SELinux 활성화 시스템 {#selinux-enabled-systems}

SELinux 활성화 시스템에서 Git 사용자의 `.ssh` 디렉토리 또는 해당 내용의 보안 컨텍스트가 손상될 수 있습니다. `sudo
gitlab-ctl reconfigure`을(를) 실행하여 이를 수정할 수 있습니다. 이 명령은 `gitlab_shell_t` 보안 컨텍스트를 `/var/opt/gitlab/.ssh`에 설정합니다.

이 동작을 개선하기 위해 `semanage`을(를) 사용하여 컨텍스트를 영구적으로 설정합니다. 런타임 종속성 `policycoreutils-python`이(가) RHEL 기반 운영 체제용 RPM 패키지에 추가되어 `semanage` 명령을 사용할 수 있도록 합니다.

#### SELinux 이슈 진단 및 해결 {#diagnose-and-resolve-selinux-issues}

Linux 패키지는 `/etc/gitlab/gitlab.rb`의 기본 경로 변경을 감지하고 올바른 파일 컨텍스트를 적용해야 합니다.

> [!note]
> GitLab 16.10 이상에서 관리자는 `gitlab-ctl apply-sepolicy`을(를) 시도하여 SELinux 이슈를 자동으로 해결할 수 있습니다. 런타임 옵션에 대해 `gitlab-ctl apply-sepolicy --help`을(를) 참조하세요.

사용자 정의 데이터 경로 구성을 사용하는 설치의 경우 관리자가 SELinux 이슈를 수동으로 해결해야 할 수 있습니다.

데이터 경로는 `gitlab.rb`을(를) 통해 변경할 수 있지만 일반적인 시나리오에서는 `symlink` 경로를 사용해야 합니다. 관리자는 `symlink` 경로가 [Gitaly 데이터 경로](settings/configuration.md#store-git-data-in-an-alternative-directory)와 같은 모든 시나리오에서 지원되지 않으므로 주의해야 합니다.

예를 들어 `/data/gitlab`이(가) `/var/opt/gitlab`을(를) 대신하는 기본 데이터 디렉토리인 경우 다음을 실행하여 보안 컨텍스트를 수정합니다:

```shell
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/authorized_keys
sudo restorecon -Rv /data/gitlab/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-shell/config.yml
sudo restorecon -Rv /data/gitlab/gitlab-shell/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-rails/etc/gitlab_shell_secret
sudo restorecon -Rv /data/gitlab/gitlab-rails/
sudo semanage fcontext --list | grep /data/gitlab/
```

정책이 적용된 후 환영 메시지를 받아 SSH 액세스가 작동하는지 확인할 수 있습니다:

```shell
ssh -T git@gitlab-hostname
```

### 모든 시스템 {#all-systems}

Git 사용자는 기본적으로 /etc/shadow에 `'!'`로 표시되는 잠긴 암호로 생성됩니다. "UsePam yes"가 활성화되지 않으면 OpenSSH 데몬은 SSH 키로도 Git 사용자가 인증하는 것을 방지합니다. 또 다른 보안 솔루션은 `/etc/shadow`에서 `'!'`을(를) `'*'`로 바꾸어 암호를 잠금 해제하는 것입니다. Git 사용자는 여전히 제한된 셸에서 실행되고 비수퍼유저용 `passwd` 명령이 새 암호 이전에 현재 암호를 입력해야 하므로 암호를 변경할 수 없습니다. 사용자가 `'*'`과(와) 일치하는 암호를 입력할 수 없으므로 계정은 계속 암호가 없습니다.

Git 사용자가 시스템에 액세스할 수 있어야 하므로 `/etc/security/access.conf`의 보안 설정을 검토하고 Git 사용자가 차단되지 않았는지 확인하세요.

## 오류: `FATAL: could not create shared memory segment: Cannot allocate memory` {#error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory}

패키지된 PostgreSQL 인스턴스는 전체 메모리의 25%를 공유 메모리로 할당하려고 시도합니다. 일부 Linux (가상) 서버에서는 사용 가능한 공유 메모리가 적어 PostgreSQL이 시작되는 것을 방지합니다. `/var/log/gitlab/postgresql/current`에서:

```plaintext
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

`/etc/gitlab/gitlab.rb`에서 PostgreSQL이 할당하려고 시도하는 공유 메모리 양을 수동으로 낮출 수 있습니다:

```ruby
postgresql['shared_buffers'] = "100MB"
```

`sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.

## 오류: `FATAL: could not open shared memory segment "/PostgreSQL.XXXXXXXXXX": Permission denied` {#error-fatal-could-not-open-shared-memory-segment-postgresqlxxxxxxxxxx-permission-denied}

기본적으로 PostgreSQL은 사용할 공유 메모리 유형을 감지하려고 시도합니다. 공유 메모리가 활성화되지 않으면 `/var/log/gitlab/postgresql/current`에서 이 오류가 표시될 수 있습니다. 이를 해결하려면 PostgreSQL의 공유 메모리 감지를 비활성화할 수 있습니다. `/etc/gitlab/gitlab.rb`에서 다음 값을 설정합니다:

```ruby
postgresql['dynamic_shared_memory_type'] = 'none'
```

`sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.

## 오류: `FATAL: remaining connection slots are reserved for non-replication superuser connections` {#error-fatal-remaining-connection-slots-are-reserved-for-non-replication-superuser-connections}

PostgreSQL에는 데이터베이스 서버에 대한 동시 연결의 최대 개수 설정이 있습니다. 기본 제한은 400입니다. 이 오류가 표시되면 GitLab 인스턴스가 이 동시 연결 제한을 초과하려고 한다는 의미입니다.

최대 연결 및 사용 가능한 연결을 확인하려면:

1. PostgreSQL 데이터베이스 콘솔을 엽니다:

   ```shell
   sudo gitlab-psql
   ```

1. 데이터베이스 콘솔에서 다음 쿼리를 실행합니다:

   ```sql
   SELECT
     (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections,
     COUNT(*) AS current_connections,
     COUNT(*) FILTER (WHERE state = 'active') AS active_connections,
     ((SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - COUNT(*)) AS remaining_connections
   FROM pg_stat_activity;
   ```

이 문제를 해결하려면 두 가지 옵션이 있습니다:

- 최대 연결 값을 증가하거나:

  1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

     ```ruby
     postgresql['max_connections'] = 600
     ```

  1. GitLab을 재구성합니다:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. GitLab을 다시 시작합니다:

     ```shell
     sudo gitlab-ctl restart
     ```

- 또는 PostgreSQL의 연결 풀러인 [PgBouncer 사용](https://docs.gitlab.com/administration/postgresql/pgbouncer/)을(를) 고려할 수 있습니다.

## 재구성에서 GLIBC 버전에 대해 불평합니다 {#reconfigure-complains-about-the-glibc-version}

```shell
$ gitlab-ctl reconfigure

/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

설치한 Linux 패키지가 서버의 OS 릴리스와 다른 OS 릴리스용으로 빌드된 경우 이런 일이 발생할 수 있습니다. 운영 체제에 대한 올바른 Linux 패키지를 다운로드하고 설치했는지 다시 한 번 확인하세요.

## 재구성이 Git 사용자를 만들 수 없습니다 {#reconfigure-fails-to-create-the-git-user}

Git 사용자로 `sudo gitlab-ctl reconfigure`을(를) 실행한 경우 이런 일이 발생할 수 있습니다. 다른 사용자로 전환하세요.

더 중요한 것은 Git 사용자나 Linux 패키지에서 사용하는 다른 사용자에게 sudo 권한을 주지 않는 것입니다. 시스템 사용자에게 불필요한 권한을 부여하면 시스템의 보안이 약화됩니다.

## sysctl을 사용하여 커널 매개 변수를 수정하지 못했습니다 {#failed-to-modify-kernel-parameters-with-sysctl}

sysctl이 커널 매개 변수를 수정할 수 없으면 다음과 같은 스택 추적 오류가 발생할 수 있습니다:

```plaintext
 * execute[sysctl] action run
================================================================================
Error executing action `run` on resource 'execute[sysctl]'
================================================================================


Mixlib::ShellOut::ShellCommandFailed
------------------------------------
Expected process to exit with [0], but received '255'
---- Begin output of /sbin/sysctl -p /etc/sysctl.conf ----
```

이는 가상화되지 않은 머신에서는 발생 가능성이 낮지만 openVZ와 같은 가상화가 있는 VPS의 경우 컨테이너에 필요한 모듈이 활성화되지 않았거나 컨테이너가 커널 매개 변수에 액세스할 수 없습니다.

sysctl에서 오류가 발생한 [모듈 활성화](https://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error)를 시도합니다.

[이 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/361)에서 설명한 보고된 해결 방법이 있으며, 이는 실패를 무시하는 스위치를 제공하여 GitLab' 내부 레시피를 편집해야 합니다. 오류를 무시하면 GitLab 서버의 성능에 예기치 않은 부작용을 미칠 수 있으므로 이렇게 하는 것은 권장되지 않습니다.

이 오류의 또 다른 변형은 파일 시스템이 읽기 전용이고 다음 스택 추적을 표시합니다:

```plaintext
 * execute[load sysctl conf] action run
    [execute] sysctl: setting key "kernel.shmall": Read-only file system
              sysctl: setting key "kernel.shmmax": Read-only file system

    ================================================================================
    Error executing action `run` on resource 'execute[load sysctl conf]'
    ================================================================================

    Mixlib::ShellOut::ShellCommandFailed
    ------------------------------------
    Expected process to exit with [0], but received '255'
    ---- Begin output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    STDOUT:
    STDERR: sysctl: setting key "kernel.shmall": Read-only file system
    sysctl: setting key "kernel.shmmax": Read-only file system
    ---- End output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    Ran cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - returned 255
```

이 오류는 가상 머신에서만 발생하는 것으로 보고되었으며 권장되는 해결 방법은 호스트에 값을 설정하는 것입니다. GitLab에 필요한 값은 가상 머신의 `/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf` 파일 내에서 찾을 수 있습니다. 호스트 OS의 `/etc/sysctl.conf` 파일에 이러한 값을 설정한 후 호스트에서 `cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -`을(를) 실행합니다. 그런 다음 가상 머신 내에서 `gitlab-ctl reconfigure`을(를) 실행해 봅니다. 커널이 이미 필요한 설정으로 실행 중이며 오류가 발생하지 않는 것을 감지해야 합니다.

다른 줄에 대해 이 프로세스를 반복해야 할 수도 있습니다. 예를 들어 `/etc/sysctl.conf`에 다음과 같은 항목을 추가한 후 재구성이 3번 실패합니다:

```plaintext
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 2048
kernel.shmmax = 17179869184
```

파일을 찾기보다는 Chef 출력의 줄을 보는 것이 더 쉬울 수 있습니다(각 오류마다 파일이 다르기 때문). 이 스니펫의 마지막 줄을 참조하세요.

```plaintext
* file[create /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf kernel.shmall] action create
  - create new file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf
  - update content in file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf from none to 6d765d
  --- /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf 2017-11-28 19:09:46.864364952 +0000
  +++ /opt/gitlab/embedded/etc/.chef-90-omnibus-gitlab-kernel.shmall.conf kernel.shmall20171128-13622-sduqoj 2017-11-28 19:09:46.864364952 +0000
  @@ -1 +1,2 @@
  +kernel.shmall = 4194304
```

## root 액세스 없이 GitLab을 설치할 수 없습니다 {#i-am-unable-to-install-gitlab-without-root-access}

때때로 사람들은 root 액세스 없이 GitLab을 설치할 수 있는지 묻습니다. 이는 여러 가지 이유로 문제가 됩니다.

### `.deb` 또는 `.rpm`을(를) 설치하는 중입니다 {#installing-the-deb-or-rpm}

우리가 아는 한 Debian 또는 RPM 패키지를 권한 없는 사용자로 설치할 수 있는 깔끔한 방법은 없습니다. 빌드 프로세스에서 소스 RPM을 만들지 않으므로 Linux 패키지 RPM을 설치할 수 없습니다.

### 포트 `80` 및 `443`에서 번거롭지 않은 호스팅 {#hassle-free-hosting-on-port-80-and-443}

GitLab을 배포하는 가장 일반적인 방법은 웹 서버(NGINX/Apache)가 GitLab과 동일한 서버에서 실행되고 웹 서버가 권한 있는(1024 미만) TCP 포트에서 수신하도록 하는 것입니다. Linux 패키지에서는 자동으로 구성된 NGINX 서비스를 번들로 제공하여 이 편의를 제공합니다. 포트 `80` 및 `443`을(를) 열기 위해 마스터 프로세스를 root로 실행해야 합니다.

이것이 문제가 되면 GitLab을 설치하는 관리자는 번들된 NGINX 서비스를 비활성화할 수 있지만, 이렇게 하면 응용 프로그램 업데이트 중에 NGINX 구성을 GitLab과 동기화하는 작업이 발생합니다.

### 서비스 간 격리 {#isolation-between-services}

Linux 패키지의 번들 서비스(GitLab 자체, NGINX, PostgreSQL 및 Redis)는 Unix 사용자 계정을 사용하여 서로 격리됩니다. 이러한 사용자 계정을 생성하고 관리하려면 root 액세스가 필요합니다. 기본적으로 Linux 패키지는 `gitlab-ctl reconfigure` 중에 필수 Unix 계정을 생성하지만 해당 동작은 [비활성화](settings/configuration.md#disable-user-and-group-account-management)할 수 있습니다.

### 더 나은 성능을 위해 운영 체제를 조정하기 {#tweaking-the-operating-system-for-better-performance}

`gitlab-ctl reconfigure` 중에 PostgreSQL 성능을 개선하고 연결 제한을 증가시키기 위해 여러 sysctl 조정을 설정하고 설치합니다. 이는 root 액세스로만 가능합니다.

## `gitlab-rake assets:precompile`이(가) `Permission denied`로 실패함 {#gitlab-rake-assetsprecompile-fails-with-permission-denied}

`gitlab-rake assets:precompile`을(를) 실행하는 일부 사용자는 Linux 패키지에서 작동하지 않는다고 보고합니다. 이에 대한 간단한 답변은 해당 명령을 실행하지 않는 것입니다. 이는 소스에서의 GitLab 설치에만 해당됩니다.

GitLab 웹 인터페이스는 Ruby on Rails 언어로 "자산"이라고 하는 CSS 및 JavaScript 파일을 사용합니다. [상위 GitLab 리포지토리](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets)에서 이러한 파일은 개발자 친화적인 방식으로 저장됩니다. 쉽게 읽고 편집할 수 있습니다. GitLab의 일반 사용자인 경우 이러한 파일이 개발자 친화적인 형식이 아니길 원합니다. GitLab이 느려지기 때문입니다. 이것이 GitLab 설정 프로세스의 일부가 자산을 개발자 친화적 형식에서 최종 사용자 친화적(컴팩트, 빠름) 형식으로 변환하는 이유입니다. 이것이 `rake assets:precompile` 스크립트의 목적입니다.

소스에서 GitLab을 설치할 때(Linux 패키지가 있기 전에 유일한 방법이었음) GitLab을 업데이트할 때마다 GitLab 서버에서 자산을 변환해야 합니다. 사람들은 이 단계를 간과하곤 했으며 `rake assets:precompile`을(를) 실행하도록 서로 권장하는 인터넷의 게시물, 댓글 및 메일이 여전히 있습니다(이제 `gitlab:assets:compile`로 이름이 변경됨). Linux 패키지를 사용하는 경우는 다릅니다. 패키지를 빌드할 때 [자산을 컴파일합니다](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74). Linux 패키지를 사용하여 GitLab을 설치하면 변환된 자산이 이미 준비되어 있습니다! 이것이 패키지에서 GitLab을 설치할 때 `rake assets:precompile`을(를) 실행할 필요가 없는 이유입니다.

`gitlab-rake assets:precompile`이(가) 권한 오류로 실패하는 것은 보안 관점에서 좋은 이유로 실패합니다. 자산을 쉽게 다시 쓸 수 없다는 사실로 인해 공격자가 GitLab 서버를 사용하여 악의적인 JavaScript 코드를 GitLab 서버의 방문자에게 제공하기가 더 어려워집니다.

사용자 정의 JavaScript 또는 CSS 코드로 GitLab을 실행하려면 소스에서 GitLab을 실행하거나 자체 패키지를 빌드하는 것이 좋습니다.

실제로 알고 있다면 다음과 같이 `gitlab-rake gitlab:assets:compile`을(를) 실행할 수 있습니다:

```shell
sudo NO_PRIVILEGE_DROP=true USE_DB=false gitlab-rake gitlab:assets:clean gitlab:assets:compile
# user and path might be different if you changed the defaults of
# user['username'], user['group'] and gitlab_rails['dir'] in gitlab.rb
sudo chown -R git:git /var/opt/gitlab/gitlab-rails/tmp/cache
```

## 오류: `Short read or OOM loading DB` {#error-short-read-or-oom-loading-db}

[이전 Redis 세션 정리](https://docs.gitlab.com/administration/operations/)를 시도합니다.

## 오류: `The requested URL returned error: 403` {#error-the-requested-url-returned-error-403}

apt 리포지토리를 사용하여 GitLab을 설치하려고 할 때 다음과 유사한 오류가 발생하면:

```shell
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

서버 앞에 `apt-cacher-ng`과(와) 같은 리포지토리 캐시가 있는지 확인합니다.

apt-cacher-ng 구성에 다음 줄을 추가합니다(예: `/etc/apt-cacher-ng/acng.conf`):

```shell
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com|*\.cloudfront\.net)
```

이 통과 규칙이 필요한 이유 및 이를 구성하는 방법에 대한 자세한 내용은 HTTPS/TLS 리포지토리에 대한 `apt-cacher-ng` 설명서를 참조하세요.

## apt-mirror를 사용하여 여러 배포판용 패키지 미러링이 실패합니다 {#mirroring-packages-for-multiple-distributions-using-apt-mirror-fails}

GitLab CE 및 GitLab EE deb 패키지는 배포판 전체에서 동일한 버전 문자열을 공유하지만 내용이 다릅니다. Debian 리포지토리 형식에서 [중복 패키지](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages)로 처리됩니다. 이는 단일 deb 리포지토리가 여러 배포판을 안전하게 제공할 수 없다는 의미입니다. 한 배포판의 패키지 메타데이터가 다른 배포판을 덮어쓸 수 있기 때문입니다.

각 배포판을 전용 경로 아래에 게시합니다. 그러나 `https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>` URL로의 요청을 호스트가 사용 중인 배포판에 따라 올바른 배포판 `https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>/<distribution>`으로 리디렉션하는 URL 리디렉션이 있으므로 사용자는 다양한 배포판에 대해 동일한 URL을 계속 사용할 수 있습니다.

그러나 `apt-mirror`과(와) 같은 미러링 도구를 사용하여 동일한 호스트에서 여러 배포판을 미러링할 때는 이 기술이 작동하지 않으므로 잘못된 배포판용 메타데이터 또는 패키지를 가져올 수 있습니다.

URL 경로에 추가하여 배포판을 명시적으로 만듭니다. 예를 들어 Jammy의 경우:

```plaintext
deb https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-ee/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-fips/ubuntu/jammy jammy main
```

이 형식을 사용하면 주요 위치는:

- `InRelease`은(는) `https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/InRelease`에 있습니다.
- `Packages.gz`은(는) `https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/main/binary-amd64/Packages.gz`에 있습니다.
- 패키지 파일은 `https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/pool/main/g/gitlab-ce/gitlab-ce_18.5.0-ce.0_amd64.deb`에 있습니다.

### `gitlab-runner` {#gitlab-runner}

`gitlab-runner` 패키지의 구성은 동일한 패키지가 배포판 전체에서 사용되기 때문에 다릅니다. URL은 그대로 유지될 수 있습니다: `https://packages.gitlab.com/runner/gitlab-runner`.

## 자체 서명된 인증서 또는 사용자 정의 인증서 기관 사용 {#using-self-signed-certificate-or-custom-certificate-authorities}

사용자 정의 인증서 기관이 있는 격리된 네트워크에서 GitLab을 설치하거나 자체 서명된 인증서를 사용하는 경우 인증서에 GitLab이 도달할 수 있는지 확인하세요. 그렇지 않으면 다음과 같은 오류가 발생합니다:

```shell
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

GitLab이 GitLab Shell과 같은 내부 서비스에 연결하려고 할 때입니다.

이러한 오류를 해결하려면 [사용자 정의 공개 인증서 설치](settings/ssl/_index.md#install-custom-public-certificates) 섹션을 참조하세요.

## 오류: `proxyRoundTripper: XXX failed with: "net/http: timeout awaiting response headers"` {#error-proxyroundtripper-xxx-failed-with-nethttp-timeout-awaiting-response-headers}

GitLab Workhorse가 1분(기본값) 내에 GitLab으로부터 응답을 받지 못하면 502 페이지를 제공합니다.

요청이 시간 초과될 수 있는 여러 가지 이유가 있습니다. 사용자가 매우 큰 diff 또는 유사한 것을 로드 중일 수 있습니다.

`/etc/gitlab/gitlab.rb`에서 값을 설정하여 기본 시간 제한 값을 증가시킬 수 있습니다:

```ruby
gitlab_workhorse['proxy_headers_timeout'] = "2m0s"
```

파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation). 변경 사항이 적용됩니다.

## 원하던 변경 사항이 거부되었습니다 {#the-change-you-wanted-was-rejected}

가장 가능성이 높은 것은 GitLab 앞에 프록시가 있는 환경에서 GitLab이 설정되어 있고 패키지에서 기본적으로 설정된 프록시 헤더가 환경에 맞지 않습니다.

기본 헤더를 재정의하는 방법에 대한 자세한 내용은 [NGINX 문서의 기본 프록시 헤더 섹션 변경](settings/nginx.md#change-the-default-proxy-headers)을(를) 참조하세요.

## CSRF 토큰 진정성을 확인할 수 없습니다 422 처리 불가능이 완료되었습니다 {#cant-verify-csrf-token-authenticity-completed-422-unprocessable}

가장 가능성이 높은 것은 GitLab 앞에 프록시가 있는 환경에서 GitLab이 설정되어 있고 패키지에서 기본적으로 설정된 프록시 헤더가 환경에 맞지 않습니다.

기본 헤더를 재정의하는 방법에 대한 자세한 내용은 [NGINX 문서의 기본 프록시 헤더 섹션 변경](settings/nginx.md#change-the-default-proxy-headers)을(를) 참조하세요.

## 확장 누락 `pg_trgm` {#extension-missing-pg_trgm}

[GitLab에는](https://docs.gitlab.com/install/postgresql_extensions/) PostgreSQL 확장 `pg_trgm`이(가) 필요합니다. 번들 데이터베이스와 함께 Linux 패키지를 사용 중이면 업그레이드 시 확장이 자동으로 활성화되어야 합니다.

그러나 외부(패키지되지 않은) 데이터베이스를 사용 중이면 확장을 수동으로 활성화해야 합니다. 이 이유는 외부 데이터베이스가 있는 Linux 패키지 인스턴스가 확장의 존재 여부를 확인할 방법이 없으며 확장을 활성화할 방법이 없기 때문입니다.

이 이슈를 해결하려면 먼저 `pg_trgm` 확장을 설치해야 합니다. 확장은 `postgresql-contrib` 패키지에 있습니다. Debian의 경우:

```shell
sudo apt-get install postgresql-contrib
```

확장이 설치된 후 `psql`을(를) 수퍼유저로 액세스하고 확장을 활성화합니다.

1. `psql`을(를) 수퍼유저로 액세스합니다:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. 확장을 활성화합니다:

   ```plaintext
   CREATE EXTENSION pg_trgm;
   \q
   ```

1. 이제 마이그레이션을 다시 실행합니다:

   ```shell
   sudo gitlab-rake db:migrate
   ```

---

Docker를 사용 중인 경우 먼저 컨테이너에 액세스한 다음 위의 명령을 실행하고 마지막으로 컨테이너를 다시 시작해야 합니다.

1. 컨테이너 액세스:

   ```shell
   docker exec -it gitlab bash
   ```

1. 위의 명령을 실행합니다.
1. 컨테이너를 다시 시작합니다:

   ```shell
   docker restart gitlab
   ```

## 오류: `Errno::ENOMEM: Cannot allocate memory during backup or upgrade` {#error-errnoenomem-cannot-allocate-memory-during-backup-or-upgrade}

[GitLab에는](https://docs.gitlab.com/install/requirements/#memory) 오류 없이 실행할 수 있도록 2GB의 사용 가능한 메모리가 필요합니다. 2GB의 메모리가 설치되어 있으면 서버의 다른 프로세스의 리소스 사용량에 따라 충분하지 않을 수 있습니다. GitLab이 업그레이드하지 않거나 백업을 실행할 때 정상적으로 실행되면 더 많은 스왑을 추가하면 문제가 해결됩니다. 정상 사용 중에 서버가 스왑을 사용하고 있다면 더 많은 RAM을 추가하여 성능을 향상시킬 수 있습니다.

## NGINX 오류: `could not build server_names_hash, you should increase server_names_hash_bucket_size` {#nginx-error-could-not-build-server_names_hash-you-should-increase-server_names_hash_bucket_size}

GitLab의 외부 URL이 기본 버킷 크기(64바이트)보다 길면 NGINX가 작동을 중지하고 로그에 이 오류가 표시될 수 있습니다. 더 큰 서버 이름을 허용하려면 `/etc/gitlab/gitlab.rb`에서 버킷 크기를 두 배로 늘립니다:

```ruby
nginx['server_names_hash_bucket_size'] = 128
```

`sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.

## NFS root_squash로 인해 재구성이 실패합니다`'root' cannot chown` {#reconfigure-fails-due-to-root-cannot-chown-with-nfs-root_squash}

```shell
$ gitlab-ctl reconfigure

================================================================================
Error executing action `run` on resource 'ruby_block[directory resource: /gitlab-data/git-data]'
================================================================================

Errno::EPERM
------------
'root' cannot chown /gitlab-data/git-data. If using NFS mounts you will need to re-export them in 'no_root_squash' mode and try again.
Operation not permitted @ chown_internal - /gitlab-data/git-data
```

NFS를 사용하여 탑재되고 `root_squash` 모드로 구성된 디렉토리가 있는 경우 이런 일이 발생할 수 있습니다. 재구성은 디렉토리의 소유권을 올바르게 설정할 수 없습니다. NFS 서버의 NFS 내보내기에서 `no_root_squash`을(를) 사용하도록 전환하거나 [스토리지 디렉토리 관리 비활성화](settings/configuration.md#disable-storage-directories-management)를 하고 권한을 직접 관리해야 합니다.

## `gitlab-runsvdir`이(가) 시작되지 않습니다 {#gitlab-runsvdir-not-starting}

이는 systemd를 사용하는 운영 체제(예: Ubuntu 18.04+, CentOS 등)에 적용됩니다.

`gitlab-runsvdir`은(는) `basic.target` 대신 `multi-user.target` 중에 시작됩니다. GitLab 업그레이드 후 이 서비스를 시작하는 데 문제가 있으면 다음 명령을 통해 시스템이 `multi-user.target`에 필요한 모든 서비스를 제대로 부팅했는지 확인해야 할 수도 있습니다:

```shell
systemctl -t target
```

모든 것이 제대로 작동하면 출력은 다음과 같이 보여야 합니다:

```plaintext
UNIT                   LOAD   ACTIVE SUB    DESCRIPTION
basic.target           loaded active active Basic System
cloud-config.target    loaded active active Cloud-config availability
cloud-init.target      loaded active active Cloud-init target
cryptsetup.target      loaded active active Encrypted Volumes
getty.target           loaded active active Login Prompts
graphical.target       loaded active active Graphical Interface
local-fs-pre.target    loaded active active Local File Systems (Pre)
local-fs.target        loaded active active Local File Systems
multi-user.target      loaded active active Multi-User System
network-online.target  loaded active active Network is Online
network-pre.target     loaded active active Network (Pre)
network.target         loaded active active Network
nss-user-lookup.target loaded active active User and Group Name Lookups
paths.target           loaded active active Paths
remote-fs-pre.target   loaded active active Remote File Systems (Pre)
remote-fs.target       loaded active active Remote File Systems
slices.target          loaded active active Slices
sockets.target         loaded active active Sockets
swap.target            loaded active active Swap
sysinit.target         loaded active active System Initialization
time-sync.target       loaded active active System Time Synchronized
timers.target          loaded active active Timers

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.

22 loaded units listed. Pass --all to see loaded but inactive units, too.
To show all installed unit files use 'systemctl list-unit-files'.
```

모든 줄에 `loaded active active`이(가) 표시되어야 합니다. 아래에 표시된 줄에서 `inactive dead`이(가) 표시되면 문제가 있을 수 있습니다:

```plaintext
multi-user.target      loaded inactive dead   start Multi-User System
```

systemd에 의해 대기 중인 작업을 확인하려면 다음을 실행합니다:

```shell
systemctl list-jobs
```

`running` 작업이 표시되면 서비스가 멈춰 GitLab이 시작되는 것을 차단할 수 있습니다. 예를 들어 일부 사용자는 Plymouth가 시작되지 않는 문제가 있었습니다:

```plaintext
  1 graphical.target                     start waiting
107 plymouth-quit-wait.service           start running
  2 multi-user.target                    start waiting
169 ureadahead-stop.timer                start waiting
121 gitlab-runsvdir.service              start waiting
151 system-getty.slice                   start waiting
 31 setvtrgb.service                     start waiting
122 systemd-update-utmp-runlevel.service start waiting
```

이 경우 Plymouth 제거를 고려하세요.

## 비Docker 컨테이너에서 init 데몬 감지 {#init-daemon-detection-in-non-docker-container}

Docker 컨테이너에서 GitLab 패키지는 `/.dockerenv` 파일의 존재를 감지하고 init 시스템의 자동 감지를 건너뜁니다. 그러나 비Docker 컨테이너(containerd, cri-o 등)에서는 해당 파일이 없고 패키지가 sysvinit로 폴백되어 설치 이슈를 발생시킬 수 있습니다. 이를 방지하기 위해 사용자는 `gitlab.rb` 파일에 다음 설정을 추가하여 init 데몬 감지를 명시적으로 비활성화할 수 있습니다:

```ruby
package['detect_init'] = false
```

이 구성을 사용 중인 경우 `gitlab-ctl reconfigure`을(를) 실행하기 전에 runit 서비스를 시작해야 하며 `runsvdir-start` 명령을 사용하여 시작해야 합니다:

```shell
/opt/gitlab/embedded/bin/runsvdir-start &
```

## `gitlab-ctl reconfigure`은(는) AWS Cloudformation을 사용하는 동안 중단됩니다 {#gitlab-ctl-reconfigure-hangs-while-using-aws-cloudformation}

GitLab systemd 단위 파일은 기본적으로 `After` 및 `WantedBy` 필드 모두에 `multi-user.target`을(를) 사용합니다. 이는 서비스가 `remote-fs` 및 `network` 대상 이후에 실행되도록 하여 GitLab이 제대로 작동하기 위해 수행됩니다.

그러나 이는 AWS Cloudformation에서 사용하는 [cloud-init](https://cloudinit.readthedocs.io/en/latest/)의 자체 단위 순서와 상충합니다.

이를 해결하기 위해 사용자는 `package['systemd_wanted_by']` 및 `package['systemd_after']` 설정을 `gitlab.rb`에서 사용하여 적절한 순서에 필요한 값을 지정하고 `sudo gitlab-ctl reconfigure`을(를) 실행할 수 있습니다. 재구성이 완료된 후 변경 사항을 적용하려면 `gitlab-runsvdir` 서비스를 다시 시작하세요.

```shell
sudo systemctl restart gitlab-runsvdir
```

## 오류: `Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)` {#error-errnoeafnosupport-address-family-not-supported-by-protocol---socket2}

GitLab을 시작할 때 다음과 유사한 오류가 발생하면:

```ruby
FATAL: Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)
```

사용 중인 호스트 이름을 확인할 수 있는지, **IPv4** 주소가 반환되는지 확인하세요:

```shell
getent hosts gitlab.example.com
# Example IPv4 output: 192.168.1.1 gitlab.example.com
# Example IPv6 output: 2002:c0a8:0101::c0a8:0101 gitlab.example.com

getent hosts localhost
# Example IPv4 output: 127.0.0.1 localhost
# Example IPv6 output: ::1 localhost
```

**IPv6** 주소 형식이 반환되면 **IPv6** 프로토콜 지원(키워드 `ipv6`)이 네트워크 인터페이스에서 활성화되어 있는지 추가로 확인하세요:

```shell
ip addr # or 'ifconfig' on older operating systems
```

**IPv6** 네트워크 프로토콜 지원이 부재하거나 비활성화되었지만 DNS 구성이 호스트 이름을 **IPv6** 주소로 확인하면 GitLab 서비스가 네트워크 연결을 설정할 수 없습니다.

이는 DNS 구성(또는 `/etc/hosts`)을 수정하여 호스트를 **IPv6** 대신 **IPv4** 주소로 확인하여 해결할 수 있습니다.

## 오류: `... bad component(expected host component: my_url.tld)` `external_url`에 밑줄이 있을 때 {#error--bad-componentexpected-host-component-my_urltld-when-external_url-contains-underscores}

`external_url`을(를) 밑줄로 설정한 경우(예: `https://my_company.example.com`) CI/CD와 관련하여 다음 이슈가 발생할 수 있습니다:

- 프로젝트의 **설정 > CI/CD** 페이지를 열 수 없습니다.
- 러너가 작업을 선택하지 않고 오류 500이 발생합니다.

그 경우 [`production.log`](https://docs.gitlab.com/administration/logs/#productionlog)에 다음 오류가 포함됩니다:

```plaintext
Completed 500 Internal Server Error in 50ms (ActiveRecord: 4.9ms | Elasticsearch: 0.0ms | Allocations: 17672)

URI::InvalidComponentError (bad component(expected host component): my_url.tld):

lib/api/helpers/related_resources_helpers.rb:29:in `expose_url'
ee/app/controllers/ee/projects/settings/ci_cd_controller.rb:19:in `show'
ee/lib/gitlab/ip_address_state.rb:10:in `with'
ee/app/controllers/ee/application_controller.rb:44:in `set_current_ip_address'
app/controllers/application_controller.rb:486:in `set_current_admin'
lib/gitlab/session.rb:11:in `with_session'
app/controllers/application_controller.rb:477:in `set_session_storage'
lib/gitlab/i18n.rb:73:in `with_locale'
lib/gitlab/i18n.rb:79:in `with_user_locale'
```

해결 방법으로 `external_url`에서 밑줄을 사용하지 마세요. 이에 대한 공개 이슈가 있습니다:  [`external_url`을(를) 밑줄로 설정하면 GitLab CI/CD 기능이 중단됩니다](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6077).

## `timeout: run: /opt/gitlab/service/gitaly` 오류로 업그레이드 실패 {#upgrade-fails-with-timeout-run-optgitlabservicegitaly-error}

재구성 실행 중 패키지 업그레이드가 실패하면 다음 오류가 표시되고 모든 Gitaly 프로세스가 중지되었는지 확인한 다음 `sudo gitlab-ctl reconfigure`을(를) 다시 실행합니다.

```plaintext
---- Begin output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
STDOUT: timeout: run: /opt/gitlab/service/gitaly: (pid 4886) 15030s, got TERM
STDERR:
---- End output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
Ran /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly returned 1
```

자세한 내용은 [이슈 341573](https://gitlab.com/gitlab-org/gitlab/-/issues/341573)을(를) 참조하세요.

## GitLab을 다시 설치할 때 재구성이 중단됨 {#reconfigure-is-stuck-when-re-installing-gitlab}

[알려진 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)로 인해 GitLab을 제거하고 다시 설치하려고 한 후 재구성 프로세스가 `ruby_block[wait for logrotate service socket] action run`에서 중단된 것을 볼 수 있습니다. 이 문제는 [GitLab 제거](https://docs.gitlab.com/install/package/#uninstall-the-linux-package) 시 `systemctl` 명령 중 하나가 실행되지 않을 때 발생합니다.

이 이슈를 해결하려면:

- GitLab을 제거할 때 모든 단계를 따랐는지 확인하고 필요하면 수행하세요.
- [이슈 7776](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)의 해결 방법을 따르세요.

## GitLab `yum` 리포지토리를 Pulp 또는 Red Hat Satellite로 미러링하는 것이 실패합니다 {#mirroring-the-gitlab-yum-repository-with-pulp-or-red-hat-satellite-fails}

<https://packages.gitlab.com/gitlab/>에 있는 Linux 패키지 `yum` 리포지토리의 직접 미러링이 [Pulp](https://pulpproject.org/) 또는 [Red Hat Satellite](https://www.redhat.com/en/technologies/management/satellite)을(를) 사용하여 동기화할 때 실패합니다. 다양한 소프트웨어로 인해 다양한 오류가 발생합니다:

- Pulp 2 또는 Satellite < 6.10은 `"Malformed repository: metadata is specified for different set of packages in filelists.xml and in other.xml"` 오류로 실패합니다.
- Satellite 6.10은 `"pkgid"` 오류로 실패합니다.
- Pulp 3 또는 Satellite > 6.10은 성공한 것처럼 보이지만 리포지토리 메타데이터만 동기화됩니다.

이러한 동기화 실패는 GitLab `yum` 미러 리포지토리의 메타데이터 이슈로 인해 발생합니다. 이 메타데이터에는 일반적으로 리포지토리의 모든 RPM에 대한 파일 목록을 포함하는 `filelists.xml.gz` 파일이 포함되어 있습니다. GitLab `yum` 리포지토리는 파일이 완전히 채워졌을 때 발생하는 크기 이슈를 해결하기 위해 이 파일을 대부분 비워 둡니다.

각 GitLab RPM에는 엄청난 수의 파일이 포함되어 있으며, 리포지토리의 많은 수의 RPM에 의해 곱해지면 완전히 채워진 경우 거대한 `filelists.xml.gz` 파일이 될 것입니다. 저장소 및 빌드 제약으로 인해 파일을 만들지만 채우지 않습니다. 빈 파일로 인해 Pulp 및 RedHat Satellite(Pulp 사용) 리포지토리 미러링 파일이 실패합니다.

자세한 내용은 [이슈 2766](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2766)을(를) 참조하세요.

### 이슈를 해결하기 {#work-around-the-issue}

이슈를 해결하려면:

1. `reposync` 또는 `createrepo`과(와) 같은 대체 RPM 리포지토리 미러링 도구를 사용하여 공식 GitLab `yum` 리포지토리의 로컬 복사본을 만듭니다. 이러한 도구는 로컬 데이터의 리포지토리 메타데이터를 다시 생성하며, 이는 완전히 채워진 `filelists.xml.gz` 파일을 만드는 것을 포함합니다.
1. Pulp 또는 Satellite를 로컬 미러로 지정합니다.

### 로컬 미러 예 {#local-mirror-example}

다음은 로컬 미러링을 수행하는 방법의 예입니다. 이 예에서는:

- [Apache](https://httpd.apache.org/)를 리포지토리의 웹 서버로 사용합니다.
- [`reposync`](https://dnf-plugins-core.readthedocs.io/en/latest/reposync.html) 및 [`createrepo`](http://createrepo.baseurl.org/)을(를) 사용하여 GitLab 리포지토리를 로컬 미러로 동기화합니다. 이 로컬 미러는 Pulp 또는 RedHat Satellite의 소스로 사용할 수 있습니다. [Cobbler](https://cobbler.github.io/)과 같은 다른 도구를 사용할 수도 있습니다.

이 예에서:

- 로컬 미러는 `RHEL 8`, `Rocky 8` 또는 `AlmaLinux 8` 시스템에서 실행 중입니다.
- 웹 서버에 사용되는 호스트 이름은 `mirror.example.com`입니다.
- Pulp 3은 로컬 미러에서 동기화합니다.
- 미러링은 [GitLab Enterprise Edition 리포지토리](https://packages.gitlab.com/gitlab/gitlab-ee)입니다.

#### Apache 서버 생성 및 구성 {#create-and-configure-an-apache-server}

다음 예제는 기본 Apache 2 서버를 설치 및 구성하여 하나 이상의 Yum 리포지토리 미러를 호스팅하는 방법을 보여줍니다. 웹 서버 구성 및 보안에 대한 자세한 내용은 [Apache](https://httpd.apache.org/) 설명서를 참조하세요.

1. `httpd`을(를) 설치합니다:

   ```shell
   sudo dnf install httpd
   ```

1. `/etc/httpd/conf/httpd.conf`에 `Directory` 스탠자를 추가합니다:

   ```apache
   <Directory "/var/www/html/repos">
   Options All Indexes FollowSymLinks
   Require all granted
   </Directory>
   ```

1. `httpd` 구성을 완료합니다:

   ```shell
   sudo rm -f /etc/httpd/conf.d/welcome.conf
   sudo mkdir /var/www/html/repos
   sudo systemctl enable httpd --now
   ```

#### 미러된 Yum 리포지토리 URL 가져오기 {#get-the-mirrored-yum-repository-url}

1. GitLab 리포지토리 `yum` 구성 파일을 설치합니다:

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   sudo dnf config-manager --disable gitlab_gitlab-ee gitlab_gitlab-ee-source
   ```

1. 리포지토리 URL을 가져옵니다:

   ```shell
   sudo dnf config-manager --dump gitlab_gitlab-ee | grep baseurl
   baseurl = https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64
   ```

   `baseurl`의 내용을 로컬 미러의 소스로 사용합니다. 예를 들어, `https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64`.

#### 로컬 미러 생성 {#create-the-local-mirror}

1. `createrepo` 패키지를 설치합니다:

   ```shell
   sudo dnf install createrepo
   ```

1. RPM을 로컬 미러로 복사하려면 `reposync`을(를) 실행합니다:

   ```shell
   sudo dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only
   ```

   `--newest-only` 옵션은 최신 RPM만 다운로드합니다. 이 옵션을 생략하면 리포지토리의 모든 RPM(약 1GB 각)이 다운로드됩니다.

1. 리포지토리 메타데이터를 다시 생성하려면 `createrepo`을(를) 실행합니다:

   ```shell
   sudo createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
   ```

로컬 미러 리포지토리는 이제 <http://mirror.example.com/repos/gitlab_gitlab-ee/>에서 사용할 수 있어야 합니다.

#### 로컬 미러 업데이트 {#update-the-local-mirror}

로컬 미러는 새 GitLab 버전이 릴리스될 때 새 RPM을 얻기 위해 주기적으로 업데이트되어야 합니다. 이를 수행하는 한 가지 방법은 `cron`을(를) 사용하는 것입니다.

`/etc/cron.daily/sync-gitlab-mirror`을(를) 다음 내용으로 만듭니다:

```shell
#!/bin/sh

dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only --delete
createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
```

`dnf reposync` 명령에서 사용되는 `--delete` 옵션은 로컬 미러에서 더 이상 해당 GitLab 리포지토리에 없는 RPM을 삭제합니다.

#### 로컬 미러 사용 {#using-the-local-mirror}

1. Pulp `repository` 및 `remote`을(를) 만듭니다:

   ```shell
   pulp rpm repository create --retain-package-versions=1 --name "gitlab-ee"
   pulp rpm remote create --name gitlab-ee --url "http://mirror.example.com/repos/gitlab_gitlab-ee/" --policy immediate
   pulp rpm repository update --name gitlab-ee --remote gitlab-ee
   ```

1. 리포지토리를 동기화합니다:

   ```shell
   pulp rpm repository sync --name gitlab-ee
   ```

   이 명령은 GitLab 리포지토리의 변경 사항으로 로컬 미러를 업데이트하기 위해 주기적으로 실행되어야 합니다.

리포지토리가 동기화된 후 게시 및 배포를 만들어 사용 가능하게 할 수 있습니다. 자세한 내용은 <https://docs.pulpproject.org/pulp_rpm/>을(를) 참조하세요.

## 오류: `E: connection refused to d20rj4el6vkp4c.cloudfront.net 443` {#error-e-connection-refused-to-d20rj4el6vkp4ccloudfrontnet-443}

`packages.gitlab.com`에 있는 당사 패키지 리포지토리에서 호스팅되는 패키지를 설치할 때, 클라이언트는 `d20rj4el6vkp4c.cloudfront.net`로 리디렉션됩니다. 에어 갭 환경의 서버는 다음과 같은 오류를 받을 수 있습니다:

```shell
E: connection refused to d20rj4el6vkp4c.cloudfront.net 443
```

```shell
Failed to connect to d20rj4el6vkp4c.cloudfront.net port 443: Connection refused
```

이 이슈를 해결하려면 세 가지 옵션이 있습니다:

- 도메인으로 허용 목록을 생성할 수 있으면 `d20rj4el6vkp4c.cloudfront.net` 끝점을 방화벽 설정에 추가합니다.
- 도메인으로 허용 목록을 생성할 수 없으면 [CloudFront IP 주소 범위](https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips)를 방화벽 설정에 추가합니다. 변경될 수 있으므로 방화벽 설정과 이 목록을 동기화된 상태로 유지해야 합니다.
- 패키지 파일을 수동으로 다운로드하여 서버에 업로드합니다.

## 오류: `503 Service Unavailable` 패키지 스토리지 작업용 {#error-503-service-unavailable-for-package-storage-operations}

일부 패키지 스토리지 구성 요소는 Google Cloud Storage(GCS)를 통해 제공됩니다. 이러한 구성 요소에는 공개 APT 리포지토리 끝점 외에 GCS 끝점에 대한 아웃바운드 HTTPS 액세스가 필요합니다. `apt update`이 `503 Service Unavailable` 오류로 실패하면 `storage.googleapis.com/packages-ops`에 대한 액세스가 차단됩니다.

이 오류를 해결하려면 방화벽 규칙이 아웃바운드 HTTPS(포트 `443`) 연결을 다음으로 허용하는지 확인하세요:

- `packages.gitlab.com`
- `storage.googleapis.com`
- Google Cloud Storage의 `packages-ops` 버킷

## `net.core.somaxconn`이(가) 너무 낮게 설정되어 있는지 확인하기 {#check-if-netcoresomaxconn-is-set-too-low}

다음은 `net.core.somaxconn`의 값이 너무 낮게 설정되어 있는지 식별하는 데 도움이 될 수 있습니다:

```shell
$ netstat -ant | grep -c SYN_RECV
4
```

`netstat -ant | grep -c SYN_RECV`의 반환 값은 설정 대기 중인 연결의 수입니다. 값이 `net.core.somaxconn`보다 크면:

```shell
$ sysctl net.core.somaxconn
net.core.somaxconn = 1024
```

시간 초과 또는 HTTP 502 오류가 발생할 수 있으며 `gitlab.rb`의 `puma['somaxconn']` 변수를 업데이트하여 이 값을 늘리는 것이 좋습니다.

## 오류: `exec request failed on channel 0` 또는 `shell request failed on channel 0` {#error-exec-request-failed-on-channel-0-or-shell-request-failed-on-channel-0}

Git over SSH를 사용하여 끌어오거나 밀어낼 때 다음 오류가 표시될 수 있습니다:

- `exec request failed on channel 0`
- `shell request failed on channel 0`

이러한 오류는 `git` 사용자의 프로세스 수가 제한을 초과하는 경우 발생할 수 있습니다.

이 이슈를 해결하려면:

1. `gitlab-shell`이(가) 실행 중인 노드의 `/etc/security/limits.conf` 파일에서 `git` 사용자의 `nproc` 설정을 증가시킵니다. 일반적으로 `gitlab-shell`은 GitLab Rails 노드에서 실행됩니다.
1. Git 끌어오기 또는 밀어내기 명령을 다시 시도하세요.

## SSH 연결 손실 후 설치가 중단됨 {#hung-installation-after-ssh-connection-loss}

원격 가상 머신에서 GitLab을 설치 중이고 SSH 연결이 끊어지면 설치가 `dpkg` 프로세스에서 중단될 수 있습니다. 설치를 다시 시작하려면:

1. `top`을(를) 실행하여 연결된 `apt` 프로세스의 프로세스 ID를 찾습니다. 이는 `dpkg` 프로세스의 부모입니다.
1. `apt` 프로세스를 `sudo kill <PROCESS_ID>`을(를) 실행하여 종료합니다.
1. 신규 설치만 수행하는 경우 `sudo gitlab-ctl cleanse`을(를) 실행합니다. 이 단계는 기존 데이터를 지우므로 업그레이드에 사용하면 안 됩니다.
1. `sudo dpkg configure -a`을(를) 실행합니다.
1. `gitlab.rb` 파일을 편집하여 원하는 외부 URL 및 누락될 수 있는 다른 구성을 포함합니다.
1. `sudo gitlab-ctl reconfigure`을(를) 실행합니다.

## GitLab 재구성 시 Redis 관련 오류 {#redis-related-error-when-reconfiguring-gitlab}

GitLab을 재구성할 때 다음 오류가 발생할 수 있습니다:

```plaintext
RuntimeError: redis_service[redis] (redis::enable line 19) had an error: RuntimeError: ruby_block[warn pending redis restart] (redis::enable line 77) had an error: RuntimeError: Execution of the command /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket INFO failed with a non-zero exit code (1)
```

오류 메시지는 Redis가 `redis-cli`과(와) 연결을 설정하려고 하는 동안 다시 시작되었거나 종료되었을 수 있음을 나타냅니다. 레시피가 `gitlab-ctl restart redis`을(를) 실행하고 즉시 버전 확인을 시도하므로 오류를 발생시키는 경쟁 조건이 있을 수 있습니다.

이 문제를 해결하려면 다음 명령을 실행합니다:

```shell
sudo gitlab-ctl reconfigure
```

실패하면 `gitlab-ctl tail redis`의 출력을 확인하고 `redis-cli`을(를) 실행해 봅니다.
