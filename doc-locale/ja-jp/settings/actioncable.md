---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Action Cable
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Action Cableは、WebSocket接続を処理するRailsエンジンです。

## ワーカープールサイズの構成 {#configuring-the-worker-pool-size}

Action Cableは、Pumaワーカーごとに個別のスレッドプールを使用します。スレッドの数は、`actioncable['worker_pool_size']`オプションを使用して構成できます。
