---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 서명
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

저희는 <https://packages.gitlab.com>에서 제공하는 다양한 OS 패키지를 공유하기 위한 패키지 호스팅 시스템을 유지합니다.

인스턴스는 이러한 패키지의 무결성을 보장하기 위해 다양한 암호화 방법을 사용합니다.

## 패키지 리포지토리 메타데이터 서명 키 {#package-repository-metadata-signing-key}

APT 및 YUM 리포지토리는 GPG 키를 사용하여 메타데이터에 서명합니다. 이 키는 설치 지침에서 지정한 리포지토리 설정 스크립트에 의해 자동으로 설치됩니다.

### 현재 리포지토리 서명 키 {#current-repository-signing-key}

다음 키는 리포지토리 메타데이터에 서명하는 데 사용됩니다.

| 키 속성 | 값 |
|:--------------|:------|
| 이름          | `GitLab B.V.` |
| 이메일         | `packages@gitlab.com` |
| 설명       | `package repository signing key` |
| 지문   | `F640 3F65 44A3 8863 DAA0 B6E0 3F01 618A 5131 2F3F` |
| 만료일        | `2028-02-06` |
| 다운로드 위치 | `https://packages.gitlab.com/gpgkey/gpg.key` |

- **2020-04-06**부터 활성화됩니다.
- 만료일이 **2024-03-01**에서 **2026-02-27**로 연장되었습니다.
- 만료일이 **2026-02-27**에서 **2028-02-06**로 연장되었습니다.

키가 만료되었다는 오류가 발생하면 [최신 리포지토리 서명 키를 가져와야](#fetch-the-latest-repository-signing-key) 합니다.

### 최신 리포지토리 서명 키 가져오기 {#fetch-the-latest-repository-signing-key}

최신 리포지토리 서명 키를 가져오려면:

{{< tabs >}}

{{< tab title="Debian/Ubuntu/Raspbian" >}}

1. 키를 다운로드합니다:

   ```shell
   sudo mkdir -p /etc/apt/keyrings
   sudo curl --fail --silent --show-error \
        --output /etc/apt/keyrings/gitlab-keyring.asc \
        --url "https://packages.gitlab.com/gpgkey/gpg.key"
   ```

1. 리포지토리 소스 파일을 업데이트하여 키를 참조합니다. `/etc/apt/sources.list.d/gitlab_gitlab-ee.list` (또는 `gitlab_gitlab-ce.list`)을 편집하고, `deb` 다음에 `[signed-by=/etc/apt/keyrings/gitlab-keyring.asc]`을 추가합니다:

   ```plaintext
   deb [signed-by=/etc/apt/keyrings/gitlab-keyring.asc] https://packages.gitlab.com/gitlab/gitlab-ee/<os>/<codename> <codename> main
   deb-src [signed-by=/etc/apt/keyrings/gitlab-keyring.asc] https://packages.gitlab.com/gitlab/gitlab-ee/<os>/<codename> <codename> main
   ```

> [!note]
> `apt-key`의 사용은 [더 이상 사용되지 않으며](https://blog.packagecloud.io/secure-solutions-for-apt-key-add-deprecated-messages/) Debian 13에서 제거되었습니다.
>
> `apt-key`을(를) 사용 중이고 `signed-by` 방법으로 마이그레이션할 수 없는 경우(`apt-key`을(를) 사용 중이면 소스 목록 파일에 `signed-by`이(가) 없음), GitLab 리포지토리의 공개 키를 업데이트하려면 다음을 root로 실행하십시오:
>
> ```shell
> curl -s "https://packages.gitlab.com/gpgkey/gpg.key" | apt-key add -
> apt-key list 3F01618A51312F3F
> ```

{{< /tab >}}

{{< tab title="CentOS/OpenSUSE/SLES" >}}

1. [`repo_gpgcheck`이(가) 활성화되어 있는지 확인](#verify-if-signature-check-is-active)합니다.
1. 현재 설치된 키의 목록을 가져오고 제거합니다:

   ```shell
   rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n' | grep -i gitlab | xargs sudo rpm -e
   ```

1. dnf 캐시를 제거합니다:

   ```shell
   sudo rm -rf /var/cache/dnf
   ```

1. [GitLab 패키지 리포지토리를 다시 추가](https://docs.gitlab.com/install/package/almalinux/#add-the-gitlab-package-repository)합니다.
1. 캐시를 다시 빌드합니다:

   ```shell
   sudo dnf makecache
   ```

{{< /tab >}}

{{< /tabs >}}

### 이전 리포지토리 서명 키 {#previous-repository-signing-keys}

다음 키들은 리포지토리 메타데이터에 서명하는 데 사용되었으며 현재 만료되었습니다.

| Sl. 번호 | 키 ID                                               | 만료일 |
|:--------|:-----------------------------------------------------|:------------|
| 1       | `1A4C 919D B987 D435 9396  38B9 1421 9A96 E15E 78F4` | `2020-04-15` |

## 패키지 서명 검증 {#package-signature-verification}

GitLab 생산 패키지의 서명을 수동 및 자동으로 검증할 수 있습니다(지원되는 경우).

### 현재 패키지 서명 키 {#current-package-signing-key}

다음 키는 리포지토리 메타데이터에 서명하는 데 사용됩니다.

| 키 속성 | 값 |
|---------------|-------|
| 이름          | `GitLab, Inc.` |
| 이메일         | `support@gitlab.com` |
| 지문   | `98BF DB87 FCF1 0076 416C 1E0B AD99 7ACC 82DD 593D` |
| 만료일        | `2028-02-16` |
| 다운로드 위치 | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg` |

### 이전 패키지 서명 키 {#previous-package-signing-keys}

| Sl. 번호 | 키 ID                                              | 해지 날짜 | 만료일  | 다운로드 위치 |
|---------|-----------------------------------------------------|-----------------|--------------|-------------------|
| 1       | `9E71 648F 3A35 EA00 CAE4 43E7 1155 1132 6BA7 34DA` | `2025-02-14`    | `2025-07-01` | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-3D645A26AB9FBD22.pub.gpg` |

### RPM 기반 배포판 {#rpm-based-distributions}

RPM 형식은 GPG 서명 기능의 전체 구현을 포함하며 해당 형식을 기반으로 하는 패키지 관리 시스템과 완전히 통합됩니다.

#### GitLab 공개 키가 있는지 확인 {#verify-gitlab-public-key-is-present}

RPM 기반 배포판에서 패키지를 검증하려면 GitLab, Inc. 공개 키가 `rpm` 키체인에 있는지 확인하십시오. 예를 들어:

```shell
rpm -q gpg-pubkey-98bfdb87fcf10076416c1e0bad997acc82dd593d-67aefdd8 --qf '%{name}-%{version}-%{release} --> %{summary}'
```

이 명령은 다음 중 하나를 생성합니다:

- 공개 키에 대한 정보입니다.
- 키가 설치되어 있지 않다는 메시지입니다. 예: `gpg-pubkey-f27eab47-60d4a67e is not installed`.

키가 없으면 가져옵니다. 예를 들어:

```shell
rpm --import https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
```

#### 서명 검사가 활성화되어 있는지 확인 {#verify-if-signature-check-is-active}

기존 설치에서 패키지 서명 검사가 활성화되어 있는지 확인하려면 리포지토리 파일의 콘텐츠를 비교합니다:

1. 리포지토리 파일이 있는지 확인합니다: `file /etc/yum.repos.d/gitlab_gitlab-*.repo`.
1. 서명 검사가 활성화되어 있는지 확인합니다: `grep gpgcheck /etc/yum.repos.d/gitlab_gitlab-*.repo`. 이 명령의 출력은 다음과 같아야 합니다:

   ```plaintext
   repo_gpgcheck=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgcheck=1
   ```

   또는

   ```plaintext
   repo_gpgcheck=1
   pkg_gpgcheck=1
   repo_gpgcheck=1
   pkg_gpgcheck=1
   ```

파일이 없으면 리포지토리가 설치되지 않았습니다. 파일이 있지만 출력이 `gpgpcheck=0`을(를) 표시하면 해당 값을 편집하여 활성화해야 합니다.

#### Linux 패키지 `rpm` 파일 검증 {#verify-a-linux-package-rpm-file}

공개 키가 있는지 확인한 후 패키지를 검증합니다:

```shell
rpm --checksig gitlab-xxx.rpm
```

### Debian 기반 배포판 {#debian-based-distributions}

Debian 패키지 형식은 공식적으로 패키지에 서명하는 방법을 포함하지 않습니다. 저희는 `debsig` 표준을 구현했으며, 이는 잘 문서화되어 있지만 대부분의 배포판에서 기본적으로 활성화되어 있지 않습니다.

Linux 패키지 `deb` 파일을 다음 중 하나의 방법으로 검증할 수 있습니다:

- 필요한 `debsigs` 정책 및 키링을 구성한 후 `debsig-verify`을(를) 사용합니다.
- 포함된 `_gpgorigin` 파일을 GnuPG로 수동으로 확인합니다.

#### `debsigs` 구성 {#configure-debsigs}

`debsigs`에 대한 정책 및 키링을 구성하는 것이 복잡할 수 있으므로 구성을 위해 `gitlab-debsigs.sh` 스크립트를 제공합니다. 이 스크립트를 사용하려면 공개 키 및 스크립트를 다운로드해야 합니다.

```shell
curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
curl -JLO "https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/scripts/gitlab-debsigs.sh"
chmod +x gitlab-debsigs.sh
sudo ./gitlab-debsigs.sh CB947AD886C8E8FD.pub.gpg
```

#### `debsig-verify`로 검증 {#verify-with-debsig-verify}

`debsig-verify`을(를) 사용하려면:

1. [`debsigs` 를 구성합니다.](#configure-debsigs)
1. `debsig-verify` 패키지를 설치합니다.
1. `debsig-verify`을(를) 실행하여 파일을 검증합니다:

   ```shell
   debsig-verify gitlab-xxx.deb
   ```

#### GnuPG로 검증 {#verify-with-gnupg}

`debsig-verify`에서 설치한 종속성을 설치하지 않으려면 대신 GnuPG를 사용할 수 있습니다:

1. 패키지 서명 공개 키를 다운로드하고 가져옵니다:

   ```shell
   curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
   gpg --import CB947AD886C8E8FD.pub.gpg
   ```

1. 서명 파일 `_gpgorigin`을(를) 추출합니다:

   ```shell
   ar x gitlab-xxx.deb _gpgorigin
   ```

1. 서명이 콘텐츠와 일치하는지 확인합니다:

   ```shell
   ar p gitlab-xxx.deb debian-binary control.tar.xz data.tar.xz | gpg --verify _gpgorigin -
   ```

   이 명령의 출력은 다음과 같이 나타나야 합니다:

   ```shell
   gpg: Signature made Wed Feb 18 18:07:22 2026 UTC
   gpg:                using RSA key 98BFDB87FCF10076416C1E0BAD997ACC82DD593D
   gpg:                issuer "support@gitlab.com"
   gpg: Good signature from "GitLab, Inc. <support@gitlab.com>" [unknown]
   Primary key fingerprint: 98BF DB87 FCF1 0076 416C  1E0B AD99 7ACC 82DD 593D
   ```

검증이 `gpg: BAD signature from "GitLab, Inc. <support@gitlab.com>" [unknown]`에서 실패하면 다음을 확인하십시오:

- 파일 이름이 올바른 순서로 작성되었습니다.
- 파일 이름이 아카이브의 콘텐츠와 일치합니다.

사용하는 Linux 배포판에 따라 아카이브의 콘텐츠가 다른 접미사를 가질 수 있습니다. 이는 명령을 적절히 조정해야 함을 의미합니다. 아카이브의 콘텐츠를 확인하려면 `ar t gitlab-xxx.deb`을(를) 실행하십시오.

예를 들어 Ubuntu Focal(20.04)의 경우:

```shell
$ ar t gitlab-ee_17.4.2-ee.0_amd64.deb
debian-binary
control.tar.xz
data.tar.xz
_gpgorigin
```
