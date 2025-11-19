---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "`omnibus-gitlab` パッケージとDockerイメージをローカルでビルドする"
---

{{< alert type="note" >}}

GitLabチームのメンバーは、これらのアーティファクトをビルドするために使用できるCIインフラストラクチャにアクセスできます。詳細については、[ドキュメント](../development/team_members.md)を参照してください。

{{< /alert >}}

## `omnibus-gitlab`パッケージ {#omnibus-gitlab-packages}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

`omnibus-gitlab`は、サポートされているオペレーティングシステム用のパッケージをビルドするために、[Omnibus](https://github.com/chef/omnibus)を使用します。Omnibusは、使用されているOSを検出し、そのOS用のパッケージをビルドします。パッケージをビルドするための環境として、OSに対応するDockerコンテナを使用する必要があります。

<!-- vale gitlab_base.SubstitutionWarning = YES -->

カスタムパッケージをローカルでビルドする方法は、[専用ドキュメント](build_package.md)に記載されています。

## オールインワンDockerイメージ {#all-in-one-docker-image}

{{< alert type="note" >}}

オールインワンのモノリシックなものとは異なり、各GitLabコンポーネントの個別のDockerイメージが必要な場合は、[CNG](https://gitlab.com/gitlab-org/build/CNG)リポジトリをチェックアウトしてください。

{{< /alert >}}

GitLabオールインワンDockerイメージは、Ubuntu 24.04用にビルドされた`omnibus-gitlab`パッケージを内部で使用します。DockerfileはCI環境で使用するように最適化されており、パッケージはインターネット経由で入手できることが期待されています。

この状況の改善については、[イシュー #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550)で検討しています。

オールインワンDockerイメージをローカルでビルドする方法は、[専用ドキュメント](build_docker_image.md)に記載されています。
