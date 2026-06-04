---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Docker 이미지를 로컬에서 빌드합니다
---

GitLab Docker 이미지는 `omnibus-gitlab`으로 생성된 Ubuntu 24.04 패키지를 사용합니다. Docker 이미지를 빌드하는 데 필요한 대부분의 파일은 `omnibus-gitlab` 리포지토리의 `Docker` 디렉토리에 있습니다. `RELEASE` 파일은 이 디렉토리에 없으며, 이 파일을 만들어야 합니다.

## `RELEASE` 파일 만들기 {#create-the-release-file}

사용 중인 패키지의 버전 세부 정보는 `RELEASE` 파일에 저장됩니다. 자신의 Docker 이미지를 빌드하려면 `docker/` 폴더에 이 파일을 만들고 다음과 유사한 내용을 포함합니다.

```plaintext
RELEASE_PACKAGE=gitlab-ee
RELEASE_VERSION=13.2.0-ee
DOWNLOAD_URL_amd64=https://example.com/gitlab-ee_13.2.00-ee.0_amd64.deb
```

- `RELEASE_PACKAGE`은 패키지가 CE 패키지인지 EE 패키지인지를 지정합니다.
- `RELEASE_VERSION`은 패키지의 버전을 지정합니다(예: `13.2.0-ee`).
- `DOWNLOAD_URL_amd64`은 패키지를 다운로드할 수 있는 amd64의 URL을 지정합니다.
- `DOWNLOAD_URL_arm64`은 패키지를 다운로드할 수 있는 arm64의 URL을 지정합니다.

> [!note]
> 이 상황을 개선하기 위해 노력 중이며 로컬에서 사용 가능한 패키지를 사용하는 중입니다 [이슈 #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550)에서.

## Docker 이미지 빌드 {#build-the-docker-image}

`RELEASE` 파일을 채운 후 Docker 이미지를 빌드하려면:

```shell
cd docker
docker build -t omnibus-gitlab-image:custom .
```

이미지는 `omnibus-gitlab-image:custom`로 빌드되고 태그됩니다.
