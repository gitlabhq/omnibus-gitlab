---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Dockerイメージをローカルでビルドする
---

GitLab Dockerイメージは、`omnibus-gitlab`で作成されたUbuntu 22.04パッケージを使用します。Dockerイメージのビルドに必要なファイルのほとんどは、`omnibus-gitlab`リポジトリの`Docker`ディレクトリにあります。`RELEASE`ファイルはこのディレクトリにはないため、このファイルを作成する必要があります。

## `RELEASE`ファイルを作成する

使用されているパッケージのバージョン詳細は、`RELEASE`ファイルに保存されます。独自のDockerイメージをビルドするには、`docker/`フォルダに次のような内容のファイルを作成します。

```plaintext
RELEASE_PACKAGE=gitlab-ee
RELEASE_VERSION=13.2.0-ee
DOWNLOAD_URL_amd64=https://example.com/gitlab-ee_13.2.00-ee.0_amd64.deb
```

- `RELEASE_PACKAGE`は、パッケージがCEパッケージかEEパッケージかを指定します。
- `RELEASE_VERSION`は、パッケージのバージョンを指定します（例：`13.2.0-ee`）。
- `DOWNLOAD_URL_amd64`は、そのパッケージをダウンロードできるamd64のURLを指定します。
- `DOWNLOAD_URL_arm64`は、そのパッケージをダウンロードできるarm64のURLを指定します。

注 **注：**この状況の改善と、ローカルで利用可能なパッケージの使用については、[イシュー#5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550)で検討しています。

## Dockerイメージをビルドする

`RELEASE`ファイルに入力された後、Dockerイメージをビルドするには、次の手順に従います。

```shell
cd docker
docker build -t omnibus-gitlab-image:custom .
```

イメージがビルドされ、`omnibus-gitlab-image:custom`としてタグ付けされます。
