---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Omnibus GitLab 릴리스 프로세스
---

주요 목표는 Linux 패키지에 어떤 버전의 GitLab이 포함되어 있는지 명확히 하는 것입니다.

## 공식 Linux 패키지가 빌드되는 방식 {#how-is-the-official-linux-package-built}

공식 패키지 빌드는 GitLab Inc에서 완전히 자동화합니다.

빌드는 두 가지 유형으로 구분할 수 있습니다:

- <https://packages.gitlab.com>로 릴리스할 패키지입니다.
- S3 버킷에서 사용 가능한 브랜치에서 빌드한 테스트 패키지입니다.

두 유형 모두 동일한 인프라에서 빌드됩니다.

## 인프라 {#infrastructure}

각 패키지는 의도된 플랫폼에서 빌드됩니다(CentOS 6 패키지는 CentOS6 서버에서 빌드되고, Debian 8 패키지는 Debian 8 서버에서 빌드되는 식입니다). 빌드 서버의 수는 다양하지만 항상 플랫폼당 최소 하나의 빌드 서버가 있습니다.

`omnibus-gitlab` 프로젝트는 GitLab CI/CD를 완전히 사용합니다. 이는 `omnibus-gitlab` 리포지토리에 대한 각 푸시가 GitLab CI/CD에서 빌드를 트리거하여 패키지를 생성한다는 의미입니다.

GitLab.com을 사용하여 Linux 패키지를 배포하므로 GitLab.com의 문제가 발생하거나 패키지의 보안 릴리스로 인해 패키지를 빌드할 별도의 리모트가 필요합니다.

이 리모트는 `https://dev.gitlab.org`에 위치합니다. `omnibus-gitlab` 프로젝트와 `https://dev.gitlab.org`의 유일한 차이점은 프로젝트에 활성 GitLab CI가 있고 빌드 서버에서 실행되는 프로젝트에 특정 러너가 할당되어 있다는 것입니다. 이는 모든 GitLab 구성 요소의 경우도 마찬가지입니다. 예를 들어 GitLab Shell은 `https://dev.gitlab.org`의 경우도 GitLab.com과 정확히 동일합니다.

모든 빌드 서버는 [러너](https://gitlab.com/gitlab-org/gitlab-runner)를 실행하며 모든 러너는 배포 키를 사용하여 `https://dev.gitlab.org`의 프로젝트에 연결됩니다. 빌드 서버는 또한 <https://packages.gitlab.com>의 공식 패키지 리포지토리에 액세스할 수 있으며 테스트 패키지를 저장하는 특별한 Amazon S3 버킷에도 액세스할 수 있습니다.

## 빌드 프로세스 {#build-process}

GitLab Inc는 [릴리스 도구 프로젝트](https://gitlab.com/gitlab-org/release-tools/tree/master)를 사용하여 모든 릴리스에 대한 릴리스 작업을 자동화합니다. 릴리스 관리자가 릴리스 프로세스를 시작하면 몇 가지 중요한 작업이 수행됩니다:

1. 프로젝트의 모든 리모트가 동기화됩니다.
1. 구성 요소의 버전이 GitLab CE/EE 리포지토리에서 읽힙니다(예: `VERSION`, `GITLAB_SHELL_VERSION`) `omnibus-gitlab` 리포지토리에 쓰입니다.
1. 특정 Git 주석 태그가 생성되어 `omnibus-gitlab` 리포지토리로 동기화됩니다.

`omnibus-gitlab` 리포지토리가 `https://dev.gitlab.org`에서 업데이트되면 GitLab CI 빌드가 트리거됩니다.

특정 단계는 `.gitlab-ci.yml` 파일의 `omnibus-gitlab` 리포지토리에서 볼 수 있습니다. 빌드는 모든 플랫폼에서 동시에 실행됩니다.

빌드 중에 `omnibus-gitlab`는 외부 라이브러리를 원본 위치에서 가져오고 GitLab, GitLab Shell, GitLab Workhorse 등의 GitLab 구성 요소는 `https://dev.gitlab.org`에서 가져옵니다.

빌드가 완료되고 .deb 또는 .rpm 패키지가 빌드되면 빌드 유형에 따라 패키지가 <https://packages.gitlab.com>로 푸시되거나 임시(30일 이상 된 파일은 삭제됨) S3 버킷으로 푸시됩니다.

## 구성 요소 버전 수동 지정 {#specifying-component-versions-manually}

### 개발 머신에서 {#on-your-development-machine}

1. 패키지할 GitLab의 태그를 선택합니다(예: `v6.6.0`).
1. `omnibus-gitlab` 리포지토리에 릴리스 브랜치를 생성합니다(예: `6-6-stable`).
1. 릴리스 브랜치가 이미 존재하는 경우(예: 패치 릴리스를 수행하고 있기 때문에) 최신 변경 사항을 로컬 머신으로 가져와야 합니다:

   ```shell
   git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # existing release branch
   ```

1. `support/set-revisions`을(를) 사용하여 `config/software/`의 파일 수정 사항을 설정합니다. 태그 이름을 사용하고 Git SHA1을 조회한 후 다운로드 원본을 `https://dev.gitlab.org`으로 설정합니다. EE 릴리스에는 `set-revisions --ee`을(를) 사용합니다:

   ```shell
   # usage: set-revisions [--ee] GITLAB_RAILS_REF GITLAB_SHELL_REF GITALY_REF GITLAB_ELASTICSEARCH_INDEXER_REF

   # For GitLab CE:
   support/set-revisions v1.2.3 v1.2.3 1.2.3 1.2.3 1.2.3

   # For GitLab EE:
   support/set-revisions --ee v1.2.3-ee v1.2.3 1.2.3 1.2.3 1.2.3
   ```

1. 릴리스 브랜치에 새 버전을 커밋합니다:

   ```shell
   git add VERSION GITLAB_SHELL_VERSION GITALY_SERVER_VERSION
   git commit
   ```

1. `omnibus-gitlab`에 GitLab 태그에 해당하는 주석 태그를 생성합니다. `omnibus-gitlab` 태그는 다음과 같습니다: `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`, 여기서 `MAJOR.MINOR.PATCH`는 GitLab 버전이고 `OTHER`는 `ce`, `ee` 또는 `rc1`(또는 `rc1.ee`) 같은 것일 수 있으며 `OMNIBUS_RELEASE`은 숫자입니다(0부터 시작):

   ```shell
   git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
   ```

   > [!warning]
   > `-` 하이픈을 `omnibus-gitlab` 태그의 어디에도 사용하지 마세요.

   업스트림 태그를 `omnibus-gitlab` 태그 시퀀스로 변환하는 예:

   | 업스트림 태그     | `omnibus-gitlab` 태그 시퀀스               |
   | ------------     | --------------------                        |
   | `v7.10.4`        | `7.10.4+ce.0`, `7.10.4+ce.1`, `...`         |
   | `v7.10.4-ee`     | `7.10.4+ee.0`, `7.10.4+ee.1`, `...`         |
   | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`, `7.11.0+rc1.ee.1`, `...` |

1. `https://gitlab.com`과 `https://dev.gitlab.org` 모두에 브랜치와 태그를 푸시합니다:

   ```shell
   git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   ```

   `https://dev.gitlab.org`에 주석 태그를 푸시하면 패키지 릴리스가 트리거됩니다.

### 패키지 게시 {#publishing-the-packages}

`https://dev.gitlab.org/gitlab/omnibus-gitlab/builds`에서 패키지 빌드 진행 상황을 추적할 수 있습니다. 성공적인 빌드 후 [`packages.gitlab.com` 리포지토리](https://packages.gitlab.com/gitlab/)로 자동으로 푸시됩니다.

### 클라우드 이미지 업데이트 {#updating-cloud-images}

클라우드 이미지 릴리스 프로세스는 여기에 문서화되어 있습니다: <https://handbook.gitlab.com/handbook/alliances/cloud-images/>.

다음과 같은 경우 새 이미지가 릴리스됩니다:

1. GitLab의 새로운 월간 릴리스가 있습니다.
1. 패치 릴리스에서 보안 취약성이 수정되었습니다.
1. 이미지에 영향을 미치는 중요한 이슈를 해결하는 패치가 있습니다.

새 이미지는 패키지 릴리스 후 3영업일 이내에 릴리스해야 합니다.

이미지 특정 릴리스 문서:

- (**더 이상 사용되지 않음**) [OpenShift](https://docs.gitlab.com/charts/development/release/).
