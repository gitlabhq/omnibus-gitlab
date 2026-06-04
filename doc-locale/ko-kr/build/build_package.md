---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 로컬에서 `omnibus-gitlab` 패키지 빌드
---

## 빌드 환경 준비 {#prepare-a-build-environment}

`omnibus-gitlab` 패키지를 빌드하기 위한 필수 빌드 도구가 포함된 Docker 이미지는 [`GitLab Omnibus Builder`](https://gitlab.com/gitlab-org/gitlab-omnibus-builder) 프로젝트의 [컨테이너 레지스트리](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/container_registry)에 있습니다.

1. [Docker Engine 설치](https://docs.docker.com/engine/install/).
   - Docker Engine은 요구 사항이며, Docker Desktop이 아닙니다.
   - [Mac용 Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) 은 [Docker 구독 서비스 계약](https://www.docker.com/legal/docker-subscription-service-agreement/)에 따라 상용 사용을 위해 유료 구독이 필요합니다. 대안을 고려하세요.

1. 패키지를 빌드하려는 OS에 대한 Docker 이미지를 가져옵니다. `omnibus-gitlab`에서 공식적으로 사용하는 현재 이미지 버전은 [CI 구성](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml)의 `BUILDER_IMAGE_REVISION` 환경 변수에서 참조됩니다.

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION}
   ```

1. `omnibus-gitlab` 소스를 복제하고 복제된 디렉터리로 이동합니다:

   ```shell
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   cd ~/omnibus-gitlab
   ```

1. 컨테이너를 시작하고 해당 셸에 진입하면서 `omnibus-gitlab` 디렉터리를 컨테이너에 마운트합니다:

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. 기본적으로 `omnibus-gitlab`은 다양한 GitLab 구성 요소의 소스를 가져오기 위해 공개 GitLab 리포지토리를 선택합니다. 환경 변수 `ALTERNATIVE_SOURCES`을 `false`으로 설정하여 `dev.gitlab.org`에서 빌드합니다.

   ```shell
   export ALTERNATIVE_SOURCES=false
   ```

   구성 요소 소스 정보는 [`.custom_sources.yml`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml) 파일에 있습니다.

1. 기본적으로 `omnibus-gitlab` 코드베이스는 CI 환경에서 사용하도록 최적화되어 있습니다. 한 가지 최적화는 GitLab CI 파이프라인에 의해 빌드되는 사전 컴파일된 Rails 자산을 재사용하는 것입니다. 빌드에서 이를 활용하는 방법을 알아보려면 [업스트림 자산 가져오기](#fetch-upstream-assets) 섹션을 확인하세요. 또는 `COMPILE_ASSETS` 환경 변수를 설정하여 패키지 빌드 중에 자산을 컴파일하도록 선택할 수 있습니다.

   ```shell
   export COMPILE_ASSETS=true
   ```

1. 기본적으로 XZ 압축을 사용하여 최종 DEB 패키지를 생성하면 Gzip에 비해 패키지 크기가 거의 30% 감소하고, 빌드 시간에 거의 영향을 미치지 않으며, 설치(압축 해제) 시간이 약간 증가합니다. 다만 시스템의 패키지 관리자도 해당 형식을 지원해야 합니다. 시스템의 패키지 관리자가 XZ 패키지를 지원하지 않으면 `COMPRESS_XZ` 환경 변수를 `false`로 설정합니다:

   ```shell
   export COMPRESS_XZ=false
   ```

1. 라이브러리 및 기타 종속성을 설치합니다:

   ```shell
   cd /omnibus-gitlab
   bundle install
   bundle binstubs --all
   ```

### 업스트림 자산 가져오기 {#fetch-upstream-assets}

GitLab 및 GitLab-FOSS 프로젝트의 파이프라인은 사전 컴파일된 자산이 있는 Docker 이미지를 생성하고 이미지를 컨테이너 레지스트리에 게시합니다. 패키지를 빌드하는 동안 시간을 절약하기 위해 이러한 이미지를 재사용하여 자산을 다시 컴파일하지 않을 수 있습니다:

1. 빌드 중인 GitLab 또는 GitLab-FOSS의 ref에 해당하는 자산 Docker 이미지를 가져옵니다. 예를 들어 최신 `master` ref에 해당하는 자산 이미지를 가져오려면 다음을 실행합니다:

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. 해당 이미지를 사용하여 컨테이너를 생성합니다:

   ```shell
   docker create --name gitlab_asset_cache registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. 컨테이너에서 호스트로 자산 디렉터리를 복사합니다:

   ```shell
   docker cp gitlab_asset_cache:/assets ~/gitlab-assets
   ```

1. 빌드 환경 컨테이너를 시작하는 동안 자산 디렉터리를 여기에 마운트합니다:

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -v ~/gitlab-assets:/gitlab-assets -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. `COMPILE_ASSETS`을 true로 설정하는 대신 자산을 찾을 수 있는 경로를 설정합니다:

   ```shell
   export ASSET_PATH=/gitlab-assets
   ```

## 패키지 빌드 {#build-the-package}

빌드 환경을 준비한 후 필요한 변경 사항을 수행한 후 제공된 Rake 작업을 사용하여 패키지를 빌드할 수 있습니다:

1. 빌드가 작동하려면 Git 작업 디렉터리가 깨끗해야 합니다. 따라서 변경 사항을 새 브랜치에 커밋합니다.

1. 패키지를 빌드하기 위해 Rake 작업을 실행합니다:

   ```shell
   bundle exec rake build:project
   ```

패키지는 빌드되어 `~/omnibus-gitlab/pkg` 디렉터리에서 사용 가능합니다.

### EE 패키지 빌드 {#build-an-ee-package}

기본적으로 `omnibus-gitlab`은 CE 패키지를 빌드합니다. EE 패키지를 빌드하려면 Rake 작업을 실행하기 전에 `ee` 환경 변수를 설정합니다:

```shell
export ee=true
```

### 빌드 중에 생성된 파일 정리 {#clean-files-created-during-build}

빌드 프로세스 중에 생성된 모든 임시 파일을 `omnibus`의 `clean` 명령을 사용하여 정리할 수 있습니다:

```shell
bin/omnibus clean gitlab
```

`--purge` purge 옵션을 추가하면 프로젝트 설치 디렉터리(`/opt/gitlab`) 및 패키지 캐시 디렉터리(`/var/cache/omnibus/pkg`)를 포함하여 빌드 중에 생성된 **전체** 파일이 제거됩니다:

```shell
bin/omnibus clean --purge gitlab
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

## Omnibus에 대한 도움말 얻기 {#get-help-on-omnibus}

Omnibus 명령줄 인터페이스에 대한 도움말을 보려면 `help` 명령을 실행합니다:

```shell
bin/omnibus help
```

<!-- vale gitlab_base.SubstitutionWarning = YES -->
