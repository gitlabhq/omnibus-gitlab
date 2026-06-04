---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Raspberry Pi에서 실행하기
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Raspberry Pi에서 GitLab Community Edition을 실행하려면 최상의 결과를 위해 최소 4GB의 RAM이 있는 최신 Pi 4가 필요합니다. Pi 3 이상과 같이 더 낮은 사양에서 GitLab을 실행할 수 있지만 권장하지 않습니다. 오래된 Pi의 CPU와 RAM이 부족하기 때문에 더 이상 패키지를 제공하지 않습니다.

장치에 충분한 메모리가 있는지 확인하려면 스왑 공간을 4GB로 확장하세요.

## GitLab 설치 {#install-gitlab}

GitLab 버전 18.0부터 Raspberry Pi용 32비트 패키지를 더 이상 제공하지 않습니다.

[64비트 Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/) 를 사용하고 [`arm64` Debian 패키지를 사용하여 GitLab을 설치](https://docs.gitlab.com/install/package/debian/)해야 합니다.

32비트 OS에서 데이터를 백업하고 64비트 OS로 복원하는 방법에 대한 자세한 내용은 [PostgreSQL 운영 체제 업그레이드](https://docs.gitlab.com/administration/postgresql/upgrading_os/)를 참조하세요.

## 실행 중인 프로세스 줄이기 {#reduce-running-processes}

Pi에서 GitLab을 실행하는 데 어려움이 있다면 실행 중인 일부 프로세스를 줄일 수 있습니다.

자세한 내용은 [메모리 제약 환경](memory_constrained_envs.md)에서 GitLab을 실행하는 방법을 참조하세요.

## 추가 권장 사항 {#additional-recommendations}

몇 가지 설정으로 GitLab 성능을 향상할 수 있습니다.

### 적절한 하드 드라이브 사용 {#use-a-proper-hard-drive}

GitLab은 SD 카드가 아닌 하드 드라이브에서 `/var/opt/gitlab`과 스왑 파일을 마운트할 때 최고의 성능을 발휘합니다. USB 인터페이스를 사용하여 외부 하드 드라이브를 Pi에 연결할 수 있습니다.

### 외부 서비스 사용 {#use-external-services}

GitLab을 외부 [데이터베이스](database.md#using-a-non-packaged-postgresql-database-management-server) 및 [Redis](https://docs.gitlab.com/administration/redis/standalone/) 인스턴스에 연결하여 Pi에서 GitLab 성능을 향상할 수 있습니다.
