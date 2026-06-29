---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "`omnibus-gitlab` パッケージをローカルでビルドする"
---

## ビルド環境を準備する {#prepare-a-build-environment}

`omnibus-gitlab`パッケージをビルドするための必要なDockerイメージとツールは、[`GitLab Omnibus Builder`](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)プロジェクトの[コンテナレジストリ](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/container_registry)にあります。

1. [Docker Engineをインストール](https://docs.docker.com/engine/install/)します。
   - Docker Engineは必須要件であり、Docker Desktopは必須ではありません。
   - [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/)は、[Docker Subscription Service Agreement](https://www.docker.com/legal/docker-subscription-service-agreement/)に従い、商用利用には有料サブスクリプションが必要です。代替案を検討してください。

1. パッケージをビルドするOSのDockerイメージをプルする。omnibus-gitlab `omnibus-gitlab`で公式に使用されているイメージの現在のバージョンは、[CI設定](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml)の`BUILDER_IMAGE_REVISION`環境変数で参照されます。

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION}
   ```

1. omnibus-gitlab `omnibus-gitlab`ソースをクローンし、クローンしたディレクトリに移動します:

   ```shell
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   cd ~/omnibus-gitlab
   ```

1. コンテナを起動してそのShellに入り、omnibus-gitlab `omnibus-gitlab`ディレクトリをコンテナにマウントします:

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. デフォルトでは、omnibus-gitlab `omnibus-gitlab`は様々なGitLabコンポーネントのソースをフェッチするために、公開GitLabリポジトリを選択します。`dev.gitlab.org`からビルドするために、環境変数`ALTERNATIVE_SOURCES`を`false`に設定します。

   ```shell
   export ALTERNATIVE_SOURCES=false
   ```

   コンポーネントのソース情報は、[`.custom_sources.yml`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml)ファイルにあります。

1. デフォルトでは、omnibus-gitlab `omnibus-gitlab`コードベースはCI環境で使用するように最適化されています。そのような最適化の1つは、GitLab CIパイプラインによってビルドされる事前にコンパイルされたRailsアセットを再利用することです。あなたのビルドでこれを活用する方法を知るには、[アップストリームアセットをフェッチ](#fetch-upstream-assets)セクションを確認してください。あるいは、パッケージのビルド中にアセットをコンパイルするには、`COMPILE_ASSETS`環境変数を設定できます。

   ```shell
   export COMPILE_ASSETS=true
   ```

1. デフォルトでは、最終的なDEBパッケージを作成するためにXZ圧縮が使用されます。これは、Gzipと比較してパッケージサイズを約30％削減し、ビルド時間の増加はほとんどなく、インストール（解凍）時間がわずかに増加します。ただし、システムのパッケージマネージャーもその形式をサポートする必要があります。システムのパッケージマネージャーがXZパッケージをサポートしていない場合、環境変数`COMPRESS_XZ`を`false`に設定します:

   ```shell
   export COMPRESS_XZ=false
   ```

1. ライブラリとその他の依存関係をインストールします:

   ```shell
   cd /omnibus-gitlab
   bundle install
   bundle binstubs --all
   ```

### アップストリームアセットをフェッチする {#fetch-upstream-assets}

GitLabおよびGitLab FOSSプロジェクトのパイプラインは、事前にコンパイルされたアセットを含むDockerイメージを作成し、コンテナレジストリに公開します。パッケージをビルドする際に、時間を節約するために、アセットを再度コンパイルする代わりにこれらのイメージを再利用できます:

1. ビルドするGitLabまたはGitLab FOSSの参照に対応するアセットDockerイメージをフェッチします。例えば、最新の`master`参照に対応するアセットイメージをプルするには、次を実行します:

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. そのイメージを使用してコンテナを作成します:

   ```shell
   docker create --name gitlab_asset_cache registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. コンテナからホストにアセットディレクトリをコピーします:

   ```shell
   docker cp gitlab_asset_cache:/assets ~/gitlab-assets
   ```

1. ビルド環境コンテナを起動する際に、アセットディレクトリをその中にマウントします:

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -v ~/gitlab-assets:/gitlab-assets -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. `COMPILE_ASSETS`をtrueに設定する代わりに、アセットが見つかるパスを設定します:

   ```shell
   export ASSET_PATH=/gitlab-assets
   ```

## パッケージをビルドする {#build-the-package}

ビルド環境を準備し、必要な変更を加えたら、提供されているRakeタスクを使用してパッケージをビルドすることができます:

1. ビルドを機能させるには、Git作業ディレクトリをクリーンにする必要があります。そのため、変更を新しいブランチにコミットしてください。

1. パッケージをビルドするためにRakeタスクを実行します:

   ```shell
   bundle exec rake build:project
   ```

パッケージはビルドされ、`~/omnibus-gitlab/pkg`ディレクトリで利用可能になります。

### EEパッケージをビルドする {#build-an-ee-package}

デフォルトでは、omnibus-gitlab `omnibus-gitlab`はCEパッケージをビルドします。EEパッケージをビルドする場合は、Rakeタスクを実行する前に環境変数`ee`を設定します:

```shell
export ee=true
```

### ビルド中に作成されたファイルをクリーンアップする {#clean-files-created-during-build}

`omnibus`の`clean`コマンドを使用して、ビルドプロセス中に生成されたすべての一時ファイルをクリーンアップできます:

```shell
bin/omnibus clean gitlab
```

`--purge`パージオプションを追加すると、ビルド中に生成された**すべて**のファイル（プロジェクトインストールディレクトリ (`/opt/gitlab`) およびパッケージキャッシュディレクトリ (`/var/cache/omnibus/pkg`) を含む）が削除されます:

```shell
bin/omnibus clean --purge gitlab
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

## Omnibusに関するヘルプを表示する {#get-help-on-omnibus}

Omnibusコマンドラインインターフェースに関するヘルプは、`help`コマンドを実行してください:

```shell
bin/omnibus help
```

<!-- vale gitlab_base.SubstitutionWarning = YES -->
