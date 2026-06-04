---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: JiHu Edition
---

> [!note]
> 이 섹션은 중국 시장의 고객인 경우에만 관련이 있습니다.

GitLab은 자신의 기술을 JiHu라고 불리는 새로운 독립 중국 회사에 라이선스했습니다. 이 독립 회사는 중국에서 GitLab 완전 DevOps 플랫폼의 도입을 촉진하고 GitLab 커뮤니티와 오픈 소스 기여를 지원할 것입니다.

자세한 내용은 [블로그 게시물 공지](https://about.gitlab.com/blog/2021/03/18/gitlab-licensed-technology-to-new-independent-chinese-company/)와 [FAQ](https://about.gitlab.com/pricing/faq-jihu/)를 참조하세요.

## 필수 요구 사항 {#prerequisites}

GitLab JiHu Edition을 설치하기 전에 시스템 [요구 사항](https://docs.gitlab.com/install/requirements/)을 검토하는 것이 매우 중요합니다. 시스템 요구 사항에는 GitLab을 지원하기 위한 최소 하드웨어, 소프트웨어, 데이터베이스 및 추가 요구 사항에 대한 세부 정보가 포함됩니다.

JiHu와 계약한 후 JiHu 담당자가 설치 프로세스의 일부로 사용할 수 있는 라이선스를 제공하기 위해 연락할 것입니다.

## JiHu Edition 패키지 설치 또는 업데이트 {#install-or-update-a-jihu-edition-package}

> [!note]
> 처음으로 설치하는 경우 기본 도메인 이름을 설정하기 위해 `EXTERNAL_URL="<GitLab URL>"` 변수를 전달해야 합니다. 설치 프로세스가 자동으로 해당 URL에서 GitLab을 구성하고 시작합니다. HTTPS를 사용하려면 인증서를 지정하기 위해 [추가 구성](settings/nginx.md#enable-https)이 필요합니다.

JiHu Edition 패키지 설치 또는 업데이트에 대한 자세한 내용은 [GitLab Jihu Edition Install](https://gitlab.cn/install/) 페이지를 참조하세요.

### 초기 비밀번호 설정 및 라이선스 적용 {#set-initial-password-and-apply-license}

GitLab JiHu Edition을 처음 설치하면 비밀번호 재설정 화면으로 리디렉션됩니다. 초기 관리자 계정의 비밀번호를 입력하면 로그인 화면으로 다시 리디렉션됩니다. 기본 계정의 사용자 이름 `root`을 사용하여 로그인합니다.

자세한 지침은 [설치 및 구성](https://docs.gitlab.com/install/package/)을 참조하세요.

또한 서버의 GitLab 관리 패널로 이동하여 [JiHu Edition 라이선스 파일을 업로드](https://docs.gitlab.com/administration/license/#uploading-your-license)할 수 있습니다.

## GitLab Enterprise Edition을 JiHu Edition으로 업데이트 {#update-gitlab-enterprise-edition-to-jihu-edition}

Linux 패키지를 사용하여 설치된 기존 GitLab Enterprise Edition (EE) 서버를 GitLab JiHu Edition (JH)로 업데이트하려면 JiHu Edition (JH) 패키지를 EE 위에 설치합니다.

사용 가능한 옵션은 다음과 같습니다:

- (권장) EE의 동일한 버전에서 JH로 업데이트합니다.
- 지원되는 [업그레이드 경로](https://docs.gitlab.com/update/#upgrade-paths)인 경우 EE의 낮은 버전에서 JH의 높은 버전으로 업데이트합니다(예: EE 13.5.4에서 JH 13.10.0).

다음 단계에서는 동일한 버전으로 업데이트한다고 가정합니다(예: EE 13.10.0에서 JH 13.10.0).

EE를 JH로 업데이트하려면:

- deb/rpm 패키지를 사용하여 GitLab을 설치한 경우:

  1. [백업](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)을 수행합니다.
  1. 현재 설치된 GitLab 버전을 찾습니다:

     - Debian/Ubuntu의 경우:

       ```shell
       sudo apt-cache policy gitlab-ee | grep Installed
       ```

       출력이 `Installed: 13.10.0-ee.0`과 유사해야 하므로 설치된 버전은 `13.10.0-ee.0`입니다.

     - CentOS/RHEL의 경우:

       ```shell
       sudo rpm -q gitlab-ee
       ```

       출력이 `gitlab-ee-13.10.0-ee.0.el8.x86_64`과 유사해야 하므로 설치된 버전은 `13.10.0-ee.0`입니다.

  1. 운영 체제에 대해 [JiHu Edition 패키지 설치](#install-or-update-a-jihu-edition-package)할 때와 동일한 단계를 따르고 이전 단계에서 기록한 것과 동일한 버전을 선택했는지 확인합니다. `<url>`를 패키지의 URL로 바꿉니다.

  1. GitLab을 재구성합니다:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. 서버의 GitLab 관리 패널(`/admin/license/new`)로 이동하여 JiHu Edition 라이선스 파일을 업로드합니다. JiHu로 업데이트하기 전에 이미 EE 라이선스가 설치되어 있다면 JH를 설치할 때 EE 라이선스가 자동으로 비활성화됩니다.

  1. GitLab이 예상대로 작동하는지 확인한 다음 이전 Enterprise Edition 리포지토리를 제거합니다:

     - Debian/Ubuntu의 경우:

       ```shell
       sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ee.list
       ```

     - CentOS/RHEL의 경우:

       ```shell
       sudo rm /etc/yum.repos.d/gitlab_gitlab-ee.repo
       sudo dnf config-manager --disable gitlab_gitlab-ee
       ```

- Docker를 사용하여 GitLab을 설치한 경우:

  1. [Docker 업데이트 가이드](https://docs.gitlab.com/install/docker/)를 따르고 `gitlab/gitlab-ee:latest`를 다음으로 바꿉니다:

     ```shell
     registry.gitlab.com/gitlab-jh/omnibus-gitlab/gitlab-jh:<version>
     ```

     `<version>`는 현재 설치된 GitLab 버전이며 다음을 사용하여 찾을 수 있습니다:

     ```shell
     sudo docker ps | grep gitlab/gitlab-ee | awk '{print $2}'
     ```

     출력은 다음과 유사해야 합니다: `gitlab/gitlab-ee:13.10.0-ee.0`, 따라서 이 경우 `<version>`는 `13.10.0`과 같습니다.

  1. 서버의 GitLab 관리 패널(`/admin/license/new`)로 이동하여 JiHu Edition 라이선스 파일을 업로드합니다. JiHu로 업데이트하기 전에 이미 EE 라이선스가 설치되어 있다면 JH를 설치할 때 EE 라이선스가 자동으로 비활성화됩니다.

완료되었습니다! 이제 GitLab JiHu Edition을 사용할 수 있습니다! 최신 버전으로 업데이트하려면 [JiHu 패키지 설치 또는 업데이트](#install-or-update-a-jihu-edition-package)를 참조하세요.

## GitLab Enterprise Edition으로 돌아가기 {#go-back-to-gitlab-enterprise-edition}

JiHu Edition 설치를 GitLab Enterprise Edition (EE)로 다운그레이드하려면 현재 설치된 Enterprise Edition 패키지의 동일한 버전을 위에 설치합니다.

GitLab EE에 대해 선호하는 설치 방법에 따라 다음 중 하나를 수행합니다:

- 공식 GitLab 패키지 리포지토리를 사용하고 [GitLab EE를 설치](https://about.gitlab.com/install/?version=ee)합니다.
- GitLab EE 패키지를 다운로드하고 [수동으로 설치](https://docs.gitlab.com/update/package/#upgrade-with-a-downloaded-package)합니다.
