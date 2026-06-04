---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "`omnibus-gitlab` 패키지 및 Docker 이미지를 로컬에서 빌드"
---

> [!note]
> GitLab 팀 멤버인 경우 이러한 아티팩트를 빌드하는 데 사용할 수 있는 CI 인프라에 액세스할 수 있습니다. 자세한 내용은 [문서](../development/team_members.md)를 확인하세요.

## `omnibus-gitlab` 패키지 {#omnibus-gitlab-packages}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

`omnibus-gitlab`은(는) 지원되는 운영 체제의 패키지를 빌드하기 위해 [Omnibus](https://github.com/chef/omnibus)를 사용합니다. Omnibus는 사용 중인 OS를 감지하고 해당 OS의 패키지를 빌드합니다. 패키지를 빌드하기 위한 환경으로 OS에 해당하는 Docker 컨테이너를 사용해야 합니다.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

사용자 지정 패키지를 로컬에서 빌드하는 방법은 [전용 문서](build_package.md)에 설명되어 있습니다.

## 올인원 Docker 이미지 {#all-in-one-docker-image}

> [!note]
> 올인원 모놀리식 이미지 대신 각 GitLab 구성 요소에 대한 개별 Docker 이미지를 원하는 경우 [CNG](https://gitlab.com/gitlab-org/build/CNG) 리포지토리를 확인하세요.

GitLab 올인원 Docker 이미지는 내부적으로 Ubuntu 24.04용으로 빌드된 `omnibus-gitlab` 패키지를 사용합니다. Dockerfile은 CI 환경에서 사용하도록 최적화되어 있으며, 패키지를 인터넷을 통해 사용할 수 있다는 예상을 포함합니다.

이 상황을 개선하는 것을 검토 중입니다 [이슈 #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

올인원 Docker 이미지를 로컬에서 빌드하는 방법은 [전용 문서](build_docker_image.md)에 설명되어 있습니다.
