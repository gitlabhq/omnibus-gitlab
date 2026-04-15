---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Omnibus GitLab 릴리즈 프로세스
---

저희의 주요 목표는 Linux 패키지에 포함된 GitLab 버전을 명확하게 표시하는 것입니다.

## 공식 Linux 패키지 빌드 방법

공식 패키지 빌드는 GitLab Inc에서 완전히 자동화하여 진행합니다.

두 가지 유형의 빌드를 구분할 수 있습니다:

- <https://packages.gitlab.com>에 릴리즈하기 위한 패키지
- S3 버킷에서 사용 가능한 브랜치에서 빌드된 테스트 패키지

두 유형 모두 동일한 인프라에서 빌드됩니다.

## 인프라

각 패키지는 해당 플랫폼에서 빌드됩니다(CentOS 6 패키지는 CentOS6 서버에서, Debian 8 패키지는 Debian 8 서버에서 빌드됩니다).
빌드 서버의 수는 다양하지만 플랫폼당 최소 하나의 빌드 서버가 항상 있습니다.

`omnibus-gitlab` 프로젝트는 GitLab CI/CD를 완전히 활용합니다. 즉, `omnibus-gitlab` 저장소에 푸시할 때마다 GitLab CI/CD에서 빌드가 트리거되어 패키지가 생성됩니다.

GitLab.com을 Linux 패키지를 사용하여 배포하므로, GitLab.com에 문제가 있거나 패키지의 보안 릴리즈로 인해 패키지를 빌드할 별도의 원격 저장소가 필요합니다.

이 원격 저장소는 `https://dev.gitlab.org`에 위치합니다. `https://dev.gitlab.org`의 `omnibus-gitlab` 프로젝트와 다른 공개 원격 저장소의 유일한 차이점은 이 프로젝트에 활성 GitLab CI가 있고 빌드 서버에서 실행되는 특정 러너가 할당되어 있다는 것입니다. 이는 모든 GitLab 구성 요소에도 해당됩니다. 예를 들어, GitLab Shell은 `https://dev.gitlab.org`에서 GitLab.com과 정확히 동일합니다.

모든 빌드 서버는 [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)를 실행하며, 모든 러너는 배포 키를 사용하여 `https://dev.gitlab.org`의 프로젝트에 연결합니다. 빌드 서버는 또한 <https://packages.gitlab.com>의 공식 패키지 저장소와 테스트 패키지를 저장하는 특별한 Amazon S3 버킷에 액세스할 수 있습니다.

## 빌드 프로세스

GitLab Inc는 [release-tools 프로젝트](https://gitlab.com/gitlab-org/release-tools/tree/master)를 사용하여 모든 릴리즈의 릴리즈 작업을 자동화합니다. 릴리즈 관리자가 릴리즈 프로세스를 시작하면 몇 가지 중요한 작업이 수행됩니다:

1. 프로젝트의 모든 원격 저장소가 동기화됩니다.
1. 구성 요소의 버전이 GitLab CE/EE 저장소에서 읽어와서
   (예: `VERSION`, `GITLAB_SHELL_VERSION`) `omnibus-gitlab` 저장소에 기록됩니다.
1. 특정 Git 태그가 생성되어 `omnibus-gitlab` 저장소에 동기화됩니다.

`https://dev.gitlab.org`의 `omnibus-gitlab` 저장소가 업데이트되면 GitLab CI 빌드가 트리거됩니다.

구체적인 단계는 `omnibus-gitlab` 저장소의 `.gitlab-ci.yml` 파일에서 확인할 수 있습니다. 빌드는 모든 플랫폼에서 동시에 실행됩니다.

빌드 중에 `omnibus-gitlab`은 소스 위치에서 외부 라이브러리를 가져오고, GitLab, GitLab Shell, GitLab Workhorse 등과 같은 GitLab 구성 요소는 `https://dev.gitlab.org`에서 가져옵니다.

빌드가 완료되고 .deb 또는 .rpm 패키지가 빌드되면, 빌드 유형에 따라 패키지가 <https://packages.gitlab.com> 또는 임시(30일 이상된 파일은 삭제됨) S3 버킷으로 푸시됩니다.

## 구성 요소 버전 수동 지정

### 개발 머신에서

1. 패키지할 GitLab 태그를 선택합니다(예: `v6.6.0`).
1. `omnibus-gitlab` 저장소에서 릴리즈 브랜치를 생성합니다(예: `6-6-stable`).
1. 패치 릴리즈를 수행하는 경우처럼 릴리즈 브랜치가 이미 존재한다면, 로컬 머신에 최신 변경 사항을 가져와야 합니다:

   ```shell
   git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # 기존 릴리즈 브랜치
   ```

1. `support/set-revisions`를 사용하여 `config/software/`의 파일 리비전을 설정합니다. 태그 이름을 가져와서 Git SHA1을 조회하고, 다운로드 소스를 `https://dev.gitlab.org`로 설정합니다. EE 릴리즈의 경우 `set-revisions --ee`를 사용합니다:

   ```shell
   # 사용법: set-revisions [--ee] GITLAB_RAILS_REF GITLAB_SHELL_REF GITALY_REF GITLAB_ELASTICSEARCH_INDEXER_REF

   # GitLab CE의 경우:
   support/set-revisions v1.2.3 v1.2.3 1.2.3 1.2.3 1.2.3

   # GitLab EE의 경우:
   support/set-revisions --ee v1.2.3-ee v1.2.3 1.2.3 1.2.3 1.2.3
   ```

1. 릴리즈 브랜치에 새 버전을 커밋합니다:

   ```shell
   git add VERSION GITLAB_SHELL_VERSION GITALY_SERVER_VERSION
   git commit
   ```

1. GitLab 태그에 해당하는 `omnibus-gitlab`에서 주석이 달린 태그를 생성합니다.
   `omnibus-gitlab` 태그는 다음과 같습니다: `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`, 여기서
   `MAJOR.MINOR.PATCH`는 GitLab 버전이고, `OTHER`는 `ce`, `ee` 또는 `rc1`(또는 `rc1.ee`)과 같은 것일 수 있으며, `OMNIBUS_RELEASE`는 숫자입니다(0부터 시작):

   ```shell
   git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
   ```

   > [!warning]
   > `omnibus-gitlab` 태그에는 하이픈 `-`을 사용하지 마세요.

   업스트림 태그를 `omnibus-gitlab` 태그 시퀀스로 변환하는 예시:

   | 업스트림 태그     | `omnibus-gitlab` 태그 시퀀스               |
   | ------------     | --------------------                        |
   | `v7.10.4`        | `7.10.4+ce.0`, `7.10.4+ce.1`, `...`         |
   | `v7.10.4-ee`     | `7.10.4+ee.0`, `7.10.4+ee.1`, `...`         |
   | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`, `7.11.0+rc1.ee.1`, `...` |

1. 브랜치와 태그를 `https://gitlab.com`과 `https://dev.gitlab.org` 모두에 푸시합니다:

   ```shell
   git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   ```

   주석이 달린 태그를 `https://dev.gitlab.org`에 푸시하면 패키지 릴리즈가 트리거됩니다.

### 패키지 게시

`https://dev.gitlab.org/gitlab/omnibus-gitlab/builds`에서 패키지 빌드 진행 상황을 추적할 수 있습니다.
빌드가 성공하면 자동으로 [`packages.gitlab.com` 저장소](https://packages.gitlab.com/gitlab/)에 푸시됩니다.

### 클라우드 이미지 업데이트

클라우드 이미지 릴리즈 프로세스는 여기에 문서화되어 있습니다: <https://handbook.gitlab.com/handbook/alliances/cloud-images/>.

새 이미지는 다음과 같은 경우에 릴리즈됩니다:

1. GitLab의 새로운 월간 릴리즈가 있을 때
1. 패치 릴리즈에서 보안 취약성이 수정되었을 때
1. 이미지에 영향을 미치는 중요한 이슈를 수정하는 패치가 있을 때

새 이미지는 패키지 릴리즈 후 3영업일 이내에 릴리즈되어야 합니다.

이미지별 릴리즈 문서:

- (**지원 중단**) [OpenShift](https://docs.gitlab.com/charts/development/release/).
