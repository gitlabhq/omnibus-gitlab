---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI 변수
---

`omnibus-gitlab` [CI 파이프라인](pipelines.md)은 CI 환경에서 제공하는 변수를 사용하여 미러 간 빌드 동작을 변경하고
민감한 데이터를 리포지토리에서 제외합니다.

파이프라인에서 사용되는 다양한 CI 변수에 대한 자세한 정보는 아래 표를 확인하세요.

## 빌드 변수

**필수**:

이 변수들은 파이프라인에서 패키지를 빌드하는 데 필요합니다.

| 환경 변수    | 설명 |
|-------------------------|-------------|
| `AWS_SECRET_ACCESS_KEY` | S3 위치에서 빌드 패키지를 읽기/쓰기하기 위한 계정 비밀 키입니다. |
| `AWS_ACCESS_KEY_ID`     | S3 위치에서 빌드 패키지를 읽기/쓰기하기 위한 계정 ID입니다. |

**사용 가능**:

이 추가 변수들은 다른 빌드 동작을 재정의하거나 활성화하는 데 사용할 수 있습니다.

| 환경 변수           | 설명 |
| ------------------------------ | ----------- |
| `AWS_MAX_ATTEMPTS`             | S3 명령이 재시도해야 하는 최대 횟수입니다. |
| `USE_S3_CACHE`                 | 임의의 값으로 설정하면 Omnibus가 가져온 소프트웨어 소스를 s3 버킷에 캐시합니다. |
| `CACHE_AWS_ACCESS_KEY_ID`      | s3 소프트웨어 가져오기 캐시가 포함된 s3 버킷에서 읽기/쓰기하기 위한 계정 ID입니다. |
| `CACHE_AWS_SECRET_ACCESS_KEY`  | s3 소프트웨어 가져오기 캐시가 포함된 s3 버킷에서 읽기/쓰기하기 위한 계정 비밀 키입니다. |
| `CACHE_AWS_BUCKET`             | 소프트웨어 가져오기 캐시를 위한 S3 버킷 이름입니다. |
| `CACHE_AWS_S3_REGION`          | 소프트웨어 가져오기 캐시를 쓰기/읽기하기 위한 S3 버킷 리전입니다. |
| `CACHE_AWS_S3_ENDPOINT`        | s3 호환 서비스를 사용할 때 요청을 보낼 HTTP 또는 HTTPS 엔드포인트입니다. |
| `CACHE_S3_ACCELERATE`          | 임의의 값을 설정하면 s3 소프트웨어 가져오기 캐시가 s3 accelerate를 사용하여 가져오기를 수행합니다. |
| `SECRET_AWS_SECRET_ACCESS_KEY` | 보안 s3 버킷에서 gpg 개인 패키지 서명 키를 읽기 위한 계정 비밀 키입니다. |
| `SECRET_AWS_ACCESS_KEY_ID`     | 보안 s3 버킷에서 gpg 개인 패키지 서명 키를 읽기 위한 계정 ID입니다. |
| `GPG_PASSPHRASE`               | gpg 개인 패키지 서명 키를 사용하는 데 필요한 암호입니다. |
| `CE_MAX_PACKAGE_SIZE_MB`       | 팀에 알림을 보내고 조사하기 전에 CE 패키지에 허용되는 최대 패키지 크기(MB)입니다. |
| `EE_MAX_PACKAGE_SIZE_MB`       | 팀에 알림을 보내고 조사하기 전에 EE 패키지에 허용되는 최대 패키지 크기(MB)입니다. |
| `DEV_GITLAB_SSH_KEY`           | `dev.gitlab.org`에서 리포지토리를 읽을 수 있는 계정의 SSH 개인 키입니다. SSH Git 가져오기에 사용됩니다. |
| `BUILDER_IMAGE_REGISTRY`       | CI 작업 이미지를 가져올 레지스트리입니다. |
| `BUILD_LOG_LEVEL`              | Omnibus 빌드 로그 레벨입니다. |
| `ALTERNATIVE_SOURCES`          | `https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml`에 나열된 사용자 정의 소스로 전환합니다. 기본값은 `true`입니다. |
| `OMNIBUS_GEM_SOURCE`           | omnibus gem을 clone할 기본이 아닌 원격 URI입니다. |
| `QA_BUILD_TARGET`              | 지정된 QA 이미지를 빌드합니다. 자세한 내용은 이 [MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91250)을 참조하세요. 기본값은 `qa`입니다. |
| `GITLAB_ASSETS_TAG`            | `gitlab-org/gitlab` 파이프라인의 `build-assets-image` 작업에서 빌드된 assets 이미지의 태그입니다. 기본값은 `$GITLAB_REF_SLUG` 또는 `gitlab-rails` 버전입니다. |
| `BUILD_ON_ALL_OS`              | `true`로 설정하면 수동 트리거를 사용하지 않고 모든 OS 이미지를 빌드합니다. |

## 테스트 변수

| 환경 변수                         | 설명 |
|----------------------------------------------|-------------|
| `RAT_REFERENCE_ARCHITECTURE`                 | RAT 작업에 의해 트리거된 파이프라인에서 사용되는 참조 아키텍처 템플릿입니다. |
| `RAT_FIPS_REFERENCE_ARCHITECTURE`            | RAT:FIPS 작업에 의해 트리거된 파이프라인에서 사용되는 참조 아키텍처 템플릿입니다. |
| `RAT_PACKAGE_URL`                            | RAT 작업에 의해 트리거된 RAT 파이프라인용 일반 패키지를 가져올 URL입니다. |
| `RAT_FIPS_PACKAGE_URL`                       | RAT 작업에 의해 트리거된 RAT 파이프라인용 FIPS 패키지를 가져올 URL입니다. |
| `RAT_TRIGGER_TOKEN`                          | RAT 파이프라인의 트리거 토큰입니다. |
| `RAT_PROJECT_ACCESS_TOKEN`                   | RAT 파이프라인을 트리거하기 위한 프로젝트 액세스 토큰입니다. |
| `OMNIBUS_GITLAB_MIRROR_PROJECT_ACCESS_TOKEN` | 테스트 패키지를 빌드하기 위한 프로젝트 액세스 토큰입니다. |
| `CI_SLACK_WEBHOOK_URL`                       | Slack 실패 알림을 위한 웹훅 URL입니다. |
| `DANGER_GITLAB_API_TOKEN`                    | dangerbot이 MR에 댓글을 게시하기 위한 GitLab API 토큰입니다. |
| `DOCS_API_TOKEN`                             | CI가 문서 사이트의 리뷰 앱 빌드를 트리거하는 데 사용하는 토큰입니다. |
| `MANUAL_QA_TEST`                             | `qa-subset-test` 작업이 자동으로 실행되어야 하는지 여부를 결정하는 데 사용되는 변수입니다. |

## 릴리스 변수

**필수**:

이 변수들은 파이프라인에서 빌드된 패키지를 릴리스하는 데 필요합니다.

| 환경 변수            | 설명 |
|---------------------------------|-------------|
| `STAGING_REPO`                  | 최종 릴리스 전에 릴리스가 업로드되는 `packages.gitlab.com`의 리포지토리입니다. |
| `STAGING_REPO_TOKEN`            | CI가 설치 스크립트를 다운로드하는 데 사용하는 PackageCloud 마스터 토큰입니다. 값은 `gitlab/pre-release` 패키지 리포지토리의 [`Tokens` 페이지](https://packages.gitlab.com/gitlab/pre-release/tokens)에서 가져옵니다. [여기 문서](https://packagecloud.io/docs#master_tokens)를 참조하세요. |
| `PACKAGECLOUD_USER`             | `packages.gitlab.com`에 패키지를 푸시하기 위한 Packagecloud 사용자명입니다. |
| `PACKAGECLOUD_TOKEN`            | `packages.gitlab.com`에 패키지를 푸시하기 위한 API 액세스 토큰입니다. 값은 [API 토큰](https://packages.gitlab.com/api_token) 페이지에서 가져와야 합니다. 이 값은 `packagecloud` CLI가 `packagecloud push`를 실행하는 데 사용됩니다. [여기 문서](https://www.rubydoc.info/gems/package_cloud/#environment-variables)를 참조하세요. |
| `LICENSE_S3_BUCKET`             | `https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html`의 공개 페이지에 게시된 릴리스 라이선스 정보를 저장하기 위한 버킷입니다. |
| `LICENSE_AWS_SECRET_ACCESS_KEY` | 라이선스 정보가 포함된 S3 버킷에서 읽기/쓰기하기 위한 계정 비밀 키입니다. |
| `LICENSE_AWS_ACCESS_KEY_ID`     | 라이선스 정보가 포함된 S3 버킷에서 읽기/쓰기하기 위한 계정 ID입니다. |
| `GCP_SERVICE_ACCOUNT`           | Google Object Storage에서 측정항목을 읽기/쓰기하는 데 사용됩니다. |
| `DOCKERHUB_USERNAME`            | Omnibus GitLab 이미지를 Docker Hub에 푸시할 때 사용되는 사용자명입니다. |
| `DOCKERHUB_PASSWORD`            | Omnibus GitLab 이미지를 Docker Hub에 푸시할 때 사용되는 비밀번호입니다. |
| `AWS_ULTIMATE_LICENSE_FILE`     | Ultimate AWS AMI를 사용하기 위한 GitLab Ultimate 라이선스입니다. |
| `AWS_PREMIUM_LICENSE_FILE`      | Ultimate AWS AMI를 사용하기 위한 GitLab Premium 라이선스입니다. |
| `AWS_AMI_SECRET_ACCESS_KEY`     | AWS AMI를 게시하기 위한 읽기/쓰기 액세스 계정 비밀 키입니다. |
| `AWS_AMI_ACCESS_KEY_ID`         | AWS AMI를 게시하기 위한 읽기/쓰기 액세스 계정 ID입니다. |
| `AWS_MARKETPLACE_ARN`           | AWS Marketplace가 공식 AMI에 액세스할 수 있도록 하는 AWS ARN입니다. |
| `PACKAGE_PROMOTION_RUNNER_TAG`  | 패키지 프로모션 작업을 실행하는 데 사용되는 공유 러너와 연결된 태그입니다. |

**사용 가능**:

이 추가 변수들은 다른 빌드 동작을 재정의하거나 활성화하는 데 사용할 수 있습니다.

| 환경 변수             | 설명 |
|----------------------------------|-------------|
| `PATCH_DEPLOY_ENVIRONMENT`       | 현재 ref가 릴리스 후보 태그인 경우 [`gitlab.com` 배포자](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) 트리거에 사용되는 배포 이름입니다. |
| `AUTO_DEPLOY_ENVIRONMENT`        | 현재 ref가 자동 배포 태그인 경우 [`gitlab.com` 배포자](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) 트리거에 사용되는 배포 이름입니다. |
| `DEPLOYER_TRIGGER_PROJECT`       | [`gitlab.com` 배포자](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md)에 사용되는 리포지토리의 GitLab 프로젝트 ID입니다. |
| `DEPLOYER_TRIGGER_TOKEN`         | 다양한 [`gitlab.com` 배포자](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) 환경의 트리거 토큰입니다. |
| `RELEASE_BUCKET`                 | 릴리스 패키지가 푸시되는 S3 버킷입니다. |
| `BUILDS_BUCKET`                  | 일반 브랜치 패키지가 푸시되는 S3 버킷입니다. |
| `RELEASE_BUCKET_REGION`          | S3 버킷 리전입니다. |
| `RELEASE_BUCKET_S3_ENDPOINT`     | S3 엔드포인트를 지정합니다. S3 호환 스토리지 서비스를 사용할 때 특히 유용합니다. |
| `GITLAB_BUNDLE_GEMFILE`          | `gitlab-rails` 번들에 필요한 Gemfile 경로를 설정합니다. 기본값은 `Gemfile`입니다. |
| `GITLAB_COM_PKGS_RELEASE_BUCKET` | 릴리스 패키지가 푸시되는 GCS 버킷입니다. |
| `GITLAB_COM_PKGS_BUILDS_BUCKET`  | 일반 브랜치 패키지가 푸시되는 GCS 버킷입니다. |
| `GITLAB_COM_PKGS_SA_FILE`        | SaaS 배포용 릴리스 패키지를 푸시하는 데 사용되는 서비스 계정 키로, pkgs 버킷에 대한 쓰기 액세스 권한이 있어야 합니다. |
| `GITLAB_NAMESPACE`               | Dev 인스턴스에서 이미지 URL을 재정의하는 데 사용됩니다. 최상위 이름이 `gitlab-org`에서 `gitlab`로 달라지기 때문입니다. |
| `PACKAGECLOUD_ENABLED`           | PackageCloud(`packages.gitlab.com`)에 패키지 업로드를 활성화하려면 `"true"`로 설정합니다. 기본값은 `"false"`입니다. [서비스 중단 이슈](https://gitlab.com/gitlab-org/build/team-tasks/-/work_items/177)를 참조하세요. |

## 알 수 없거나 오래된 변수

| 환경 변수           | 설명 |
|--------------------------------|-------------|
| `VERSION_TOKEN`                |             |
| `TAKEOFF_TRIGGER_TOKEN`        |             |
| `TAKEOFF_TRIGGER_PROJECT`      |             |
| `RELEASE_TRIGGER_TOKEN`        |             |
| `GITLAB_DEV`                   |             |
| `FOG_REGION`                   |             |
| `FOG_PROVIDER`                 |             |
| `FOG_DIRECTORY`                |             |
| `AWS_RELEASE_TRIGGER_TOKEN`    | 13.10보다 오래된 릴리스에 사용됩니다. |
| `ASSETS_AWS_SECRET_ACCESS_KEY` |             |
| `ASSETS_AWS_ACCESS_KEY_ID`     |             |
| `AMI_LICENSE_FILE`             |             |

## DockerHub 변수

기본적으로 CI는 DockerHub의 이미지를 사용합니다. 기본/공유 러너와
배포 러너는 속도 제한에 걸리지 않도록 DockerHub 미러를 사용합니다.

캐싱이나 미러링을 사용하지 않는 사용자 정의 러너를 사용하는 경우,
`DOCKERHUB_PREFIX`를 프록시로 설정하여 의존성 프록시를 활성화해야 합니다.
예를 들어 `DOCKERHUB_PREFIX: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}`와
`DEPENDENCY_PROXY_LOGIN="true"`로 설정합니다.

컨테이너 빌드 컨텍스트는 기본적으로 gcr DockerHub 미러를 사용합니다. 이
동작은 `DOCKER_OPTIONS` 또는 `DOCKER_MIRROR` 변수를 재정의하여 변경할 수 있습니다.
