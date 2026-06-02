---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Action Cable
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Action Cable은 웹소켓 연결을 처리하는 Rails 엔진입니다.

## 워커 풀 크기 구성 {#configuring-the-worker-pool-size}

Action Cable은 Puma 워커당 별도의 스레드 풀을 사용합니다. `actioncable['worker_pool_size']` 옵션을 사용하여 스레드의 개수를 구성할 수 있습니다.
