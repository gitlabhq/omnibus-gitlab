---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly Cluster (Praefect)
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Gitalyクラスタ (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)は、リポジトリにフォールトトレラントなストレージを提供します。Praefectを、Gitalyのルーターおよびトランザクションマネージャーとして使用します。

## Gitaly Cluster (Praefect)を有効にする {#enable-gitaly-cluster-praefect}

デフォルトでは、Gitaly Cluster (Praefect)は有効になっていません。Gitaly Cluster (Praefect)を有効にする方法については、Gitaly Cluster (Praefect)の[セットアップ手順](https://docs.gitlab.com/administration/gitaly/praefect/configure/#setup-instructions)を参照してください。

## Gitaly Cluster (Praefect)が有効になっている場合にGitLabを更新する {#update-gitlab-when-gitaly-cluster-praefect-is-enabled}

Gitaly Cluster (Praefect)が有効になっている状態でGitLabを更新する方法については、[特定の手順](https://docs.gitlab.com/update/zero_downtime/#praefect-gitaly-cluster)を参照してください。
