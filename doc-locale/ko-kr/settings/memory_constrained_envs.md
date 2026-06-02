---
stage: Data Stores
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 메모리가 제한된 환경에서 GitLab 실행
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 모든 기능이 활성화되어 실행될 때 상당한 양의 메모리가 필요합니다. 모든 기능이 필요하지 않은 소규모 설치에서 GitLab을 실행하는 등의 사용 사례가 있습니다. 예시는 다음과 같습니다:

- 개인용 또는 매우 소규모 팀을 위해 GitLab을 실행합니다.
- 비용 절감을 위해 클라우드 제공자에서 소규모 인스턴스를 사용합니다.
- Raspberry PI와 같은 리소스가 제한된 장치를 사용합니다.

일부 조정을 통해 GitLab은 [최소 요구 사항](https://docs.gitlab.com/install/requirements/) 또는 [참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/)에 설명된 것보다 훨씬 낮은 사양에서 편리하게 실행될 수 있습니다.

이러한 설정이 적용되면 대부분의 GitLab 부분이 작동하지만 제품 기능 및 성능이 예기치 않게 저하될 수 있습니다.

> [!note]
> 다음 섹션에서는 개별 Git 리포지토리의 크기가 100 MB를 넘지 않는 최대 5명의 개발자로 GitLab을 실행하는 방법을 설명합니다.

## 제한된 환경의 최소 요구 사항 {#minimum-requirements-for-constrained-environments}

GitLab을 실행할 수 있는 최소 예상 사양은 다음과 같습니다:

- Linux 기반 시스템(이상적으로 Debian 기반 또는 RedHat 기반)
- ARM7/ARM64의 4개 CPU 코어 또는 AMD64 아키텍처의 1개 CPU 코어
- 최소 2GB RAM + 1GB SWAP, 최적은 2.5GB RAM + 1GB 스왑
- 20GB의 사용 가능한 저장소
- 좋은 무작위 I/O 성능을 갖춘 저장소(우선순위 순서):
  - [SSD](https://en.wikipedia.org/wiki/Solid-state_drive)
  - [eMMC](https://magazine.odroid.com/article/emmc-memory-modules-a-simple-guide/)
  - [HDD](https://en.wikipedia.org/wiki/Hard_disk_drive)
  - [고성능 A1 타입 SD 카드](https://www.sdcard.org/developers/sd-standard-overview/application-performance-class/)

위의 목록 중에서 CPU의 단일 코어 성능과 저장소의 무작위 I/O 성능이 가장 큰 영향을 미칩니다. 저장소는 특히 관련이 있습니다. 제한된 환경에서는 어느 정도의 메모리 스왑이 발생할 것으로 예상되며, 이는 사용된 디스크에 더 많은 압력을 가합니다. 소규모 플랫폼의 제한된 성능의 일반적인 문제는 매우 느린 디스크 저장소이며, 이는 시스템 전체의 병목 현상으로 이어집니다.

이러한 최소 설정으로 시스템은 정상적인 작동 중에 스왑을 사용해야 합니다. 모든 구성 요소가 동시에 사용되지 않으므로 허용 가능한 성능을 제공해야 합니다.

## 시스템 성능 검증 {#validate-the-performance-of-your-system}

Linux 기반 시스템의 성능을 검증할 수 있도록 하는 많은 도구가 있습니다. 시스템 성능을 확인하는 데 도움이 될 수 있는 프로젝트 중 하나는 [sbc-bench](https://github.com/ThomasKaiser/sbc-bench)입니다. 이는 시스템 테스트의 모든 주의사항과 다양한 동작이 시스템 성능에 미치는 영향을 설명하며, 이는 임베드된 시스템에서 GitLab을 실행할 때 특히 중요합니다. 이를 사용하여 시스템 성능이 제한된 환경에서 GitLab을 실행하기에 충분한지 검증할 수 있습니다.

이러한 시스템들은 GitLab의 소규모 설치를 실행하기에 적절한 성능을 제공합니다:

- [Raspberry PI 4 2GB](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/).
- [DigitalOcean Basic 2GB with SSD](https://www.digitalocean.com/pricing).
- [Scaleway DEV1-S 2GB/20GB](https://www.scaleway.com/en/pricing/).
- [GCS e2-small](https://cloud.google.com/compute/docs/machine-resource).

## 스왑 구성 {#configure-swap}

GitLab을 설치하기 전에 스왑을 구성해야 합니다. 스왑은 물리 RAM이 가득 찼을 때 사용되는 디스크의 전용 공간입니다. Linux 시스템의 RAM이 부족하면 비활성 페이지가 RAM에서 스왑 공간으로 이동됩니다.

스왑 사용은 지연 시간을 증가시킬 수 있으므로 문제로 간주되는 경우가 많습니다. 그러나 GitLab이 작동하는 방식 때문에 할당된 메모리의 대부분이 자주 액세스되지 않습니다. 스왑을 사용하면 애플리케이션이 정상적으로 실행되고 작동할 수 있으며, 때때로 스왑만 사용할 수 있습니다.

일반적인 지침은 스왑을 사용 가능한 메모리의 약 50%로 구성하는 것입니다. 메모리가 제한된 환경의 경우 시스템에 최소 1GB의 스왑을 구성하는 것이 좋습니다. 이를 수행하는 방법에 대한 여러 가이드가 있습니다:

- [Ubuntu 20.04에서 스왑 공간을 추가하는 방법](https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-20-04/)
- [CentOS 7에서 스왑 공간을 추가하는 방법](https://linuxize.com/post/how-to-add-swap-space-on-centos-7/)

구성이 완료되면 스왑이 제대로 활성화되었는지 확인해야 합니다:

```shell
free -h
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       115Mi       1.4Gi       0.0Ki       475Mi       1.6Gi
Swap:         1.0Gi          0B       1.0Gi
```

`/proc/sys/vm/swappiness`을 조정하여 시스템이 스왑 공간을 사용하는 빈도를 구성할 수도 있습니다. 스왑 성향은 `0`과 `100` 사이에서 범위를 나타냅니다. 기본값은 `60`입니다. 낮은 값은 Linux가 익명 메모리 페이지를 해제하고 스왑에 쓰려는 기본 설정을 줄이지만, 파일 기반 페이지의 경우 동일한 작업을 수행하려는 기본 설정을 높입니다:

1. 현재 세션에서 구성합니다:

   ```shell
   sudo sysctl vm.swappiness=10
   ```

1. `/etc/sysctl.conf`을 편집하여 영구적으로 설정합니다:

   ```shell
   vm.swappiness=10
   ```

## GitLab 설치 {#install-gitlab}

메모리가 제한된 환경에서는 적합한 GitLab 배포판을 고려해야 합니다.

[GitLab Enterprise Edition(EE)](https://about.gitlab.com/install/) 은 [GitLab Community Edition(CE)](https://about.gitlab.com/install/?version=ce)보다 훨씬 더 많은 기능이 포함되어 있지만, 이러한 모든 추가 기능은 계산 및 메모리 요구 사항을 증가시킵니다.

메모리 소비가 주요 관심사인 경우 GitLab CE를 설치합니다. 나중에 언제든지 [GitLab EE로 업그레이드](https://docs.gitlab.com/update/convert_to_ee/package/)할 수 있습니다.

## Puma 최적화 {#optimize-puma}

기본적으로 GitLab은 많은 동시 연결을 처리하도록 설계된 구성으로 실행됩니다.

높은 처리량이 필요하지 않은 소규모 설치의 경우 [Puma 클러스터형 모드를 비활성화](https://docs.gitlab.com/administration/operations/puma/#disable-puma-clustered-mode-in-memory-constrained-environments)합니다. 이 구성은 단일 Puma 프로세스만 실행하여 애플리케이션을 제공합니다.

`/etc/gitlab/gitlab.rb`에서:

```ruby
puma['worker_processes'] = 0
```

이 최적화를 통해 100-400MB의 메모리 사용량 감소를 관찰했습니다.

## Sidekiq 최적화 {#optimize-sidekiq}

Sidekiq은 백그라운드 처리 데몬입니다. GitLab으로 기본 구성할 때 `20`의 동시성 모드로 실행됩니다. 이는 주어진 시간에 할당할 수 있는 메모리 양에 영향을 미칩니다. `5` 또는 `10` (권장)의 훨씬 더 작은 값을 사용하도록 구성하는 것이 좋습니다.

`/etc/gitlab/gitlab.rb`에서:

```ruby
sidekiq['concurrency'] = 10
```

## Gitaly 최적화 {#optimize-gitaly}

Gitaly는 Git 기반 리포지토리에 효율적으로 액세스할 수 있게 하는 저장소 서비스입니다. Gitaly에서 적용한 최대 동시성 및 메모리 제한을 구성하는 것이 좋습니다.

`/etc/gitlab/gitlab.rb`에서:

```ruby
gitaly['configuration'] = {
    concurrency: [
      {
        'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
        'max_per_repo' => 3,
      }, {
        'rpc' => "/gitaly.SSHService/SSHUploadPack",
        'max_per_repo' => 3,
      },
    ],
    cgroups: {
        repositories: {
            count: 2,
        },
        mountpoint: '/sys/fs/cgroup',
        hierarchy_root: 'gitaly',
        memory_bytes: 500000,
        cpu_shares: 512,
    },
}

gitaly['env'] = {
  'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
}
```

## 모니터링 비활성화 {#disable-monitoring}

GitLab은 기본적으로 모든 서비스를 활성화하여 추가 구성 없이 완전한 DevOps 솔루션을 제공합니다. 모니터링과 같은 일부 기본 서비스는 GitLab이 작동하는 데 필수적이지 않으며 메모리를 절약하기 위해 비활성화할 수 있습니다.

`/etc/gitlab/gitlab.rb`에서:

```ruby
alertmanager['enable'] = false
gitlab_exporter['enable'] = false
gitlab_kas['enable'] = false
node_exporter['enable'] = false
postgres_exporter['enable'] = false
prometheus_monitoring['enable'] = false
prometheus['enable'] = false
puma['exporter_enabled'] = false
redis_exporter['enable'] = false
sidekiq['metrics_enabled'] = false
```

이러한 방식으로 GitLab을 구성하여 300MB의 메모리 사용량 감소를 관찰했습니다.

## GitLab이 메모리를 처리하는 방식 구성 {#configure-how-gitlab-handles-memory}

GitLab은 많은 구성 요소(Ruby 및 Go로 작성됨)로 구성되며, GitLab Rails는 가장 크고 가장 많은 메모리를 소비합니다.

GitLab Rails는 [jemalloc](https://github.com/jemalloc/jemalloc) 을 메모리 할당자로 사용합니다. [jemalloc](https://github.com/jemalloc/jemalloc)은 성능을 향상시키기 위해 더 오래 유지되는 더 큰 청크에 메모리를 미리 할당합니다. 어느 정도의 성능 손실을 감수하고 GitLab을 구성하여 메모리가 더 이상 필요 없을 때 즉시 메모리를 확보할 수 있습니다.

`/etc/gitlab/gitlab.rb`에서:

```ruby
gitlab_rails['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}

gitaly['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}
```

애플리케이션 실행 중에 훨씬 더 안정적인 메모리 사용을 관찰했습니다.

## 추가 애플리케이션 내 모니터링 비활성화 {#disable-additional-in-application-monitoring}

GitLab은 내부 데이터 구조를 사용하여 자신의 다양한 측면을 측정합니다. 모니터링이 비활성화된 경우 이러한 기능은 더 이상 필요하지 않습니다.

이러한 기능을 비활성화하려면 GitLab의 **운영자** 영역으로 이동하고 Prometheus 측정항목 기능을 비활성화합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정 > 측정항목 및 프로파일링**을 선택합니다.
1. **측정항목 - Prometheus**를 확장합니다.
1. **Enable Prometheus Metrics**를 비활성화합니다.
1. **변경사항 저장**을 선택합니다.

## 모든 변경 사항이 있는 구성 {#configuration-with-all-the-changes}

1. 지금까지 설명한 모든 사항을 적용하면 `/etc/gitlab/gitlab.rb` 파일에 다음 구성이 포함되어야 합니다:

   ```ruby
   puma['worker_processes'] = 0

   sidekiq['concurrency'] = 10

   prometheus_monitoring['enable'] = false

   gitlab_rails['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
   }

   gitaly['configuration'] = {
     concurrency: [
       {
         'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
         'max_per_repo' => 3,
       }, {
         'rpc' => "/gitaly.SSHService/SSHUploadPack",
         'max_per_repo' => 3,
       },
     ],
     cgroups: {
       repositories: {
         count: 2,
       },
       mountpoint: '/sys/fs/cgroup',
       hierarchy_root: 'gitaly',
       memory_bytes: 500000,
       cpu_shares: 512,
     },
   }
   gitaly['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000',
     'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
   }
   ```

1. 모든 이러한 변경을 수행한 후 GitLab을 재구성하여 새 설정을 사용합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   이 작업은 GitLab이 지금까지 메모리 절약 설정으로 작동하지 않았으므로 시간이 걸릴 수 있습니다.

## 성능 결과 {#performance-results}

위의 구성을 적용한 후 다음 메모리 사용량을 예상할 수 있습니다:

```plaintext
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       1.7Gi       151Mi        31Mi       132Mi       102Mi
Swap:         1.0Gi       153Mi       870Mi
```
