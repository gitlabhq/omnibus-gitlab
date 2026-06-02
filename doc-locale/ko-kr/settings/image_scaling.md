---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 이미지 스케일링
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 사이트 렌더링 성능을 개선하기 위해 내장 이미지 스케일러를 실행합니다. 기본적으로 활성화되어 있습니다.

## 스케일러 구성 {#configure-the-scaler}

대다수의 GitLab 배포에서 작동하는 합리적인 기본값을 설정하기 위해 노력합니다. 그러나 이미지 크기 조정을 조정하여 원하는 성능 프로필과 가장 잘 일치하도록 하는 여러 설정을 제공합니다.

### 이미지 스케일러의 최대 개수 {#maximum-number-of-image-scalers}

이미지 크기를 조정하면 Workhorse가 실행되는 동일한 노드에서 실행되는 추가 단기 프로세스가 발생합니다. 기본적으로 이러한 프로세스가 동시에 실행되도록 허용되는 개수를 해당 머신 또는 VM의 CPU 코어 수의 절반으로 제한하되, 최소 2개 이상입니다.

대신 이 값을 고정된 값으로 설정하도록 선택할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음을 추가합니다:

   ```ruby
   gitlab_workhorse['image_scaler_max_procs'] = 10
   ```

1. 변경 사항이 적용되도록 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

이는 이미 10개의 이미지가 처리 중인 경우 11번째 요청이 크기 조정되지 않고 대신 원본 크기로 제공됨을 의미합니다. 높은 로드 상황에서도 시스템이 사용 가능한 상태로 유지되도록 하려면 이에 상한을 설정하는 것이 중요합니다.

### 최대 이미지 파일 크기 {#maximum-image-file-size}

기본적으로 GitLab은 최대 250kB 크기의 이미지만 크기 조정합니다. 이는 Workhorse 노드에서 과도한 메모리 소비를 방지하고 지연 시간을 합리적인 범위 내로 유지하기 위함입니다. 특정 파일 크기를 초과하면 실제로는 원본 이미지를 제공하는 것이 전체적으로 더 빠릅니다.

최대 허용 파일 크기를 낮추거나 높이려는 경우:

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음을 추가합니다:

   ```ruby
   gitlab_workhorse['image_scaler_max_filesize'] = 1024 * 1024
   ```

1. 변경 사항이 적용되도록 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

이는 최대 1MB의 이미지를 크기 조정할 수 있음을 의미합니다(단위는 바이트).

### 이미지 스케일러 비활성화 {#disabling-the-image-scaler}

이미지 크기 조정을 완전히 끌 수 있습니다. 이는 각 기능 플래그를 끔으로써 달성할 수 있습니다:

```ruby
Feature.disable(:dynamic_image_resizing)
```

[기능 플래그 설명서](https://docs.gitlab.com/administration/feature_flags/)를 참고하여 기능 플래그로 작업하는 방법을 알아보세요.
