---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "`omnibus-gitlab` パッケージをローカルでビルドする"
---

## ビルド環境を準備する {#prepare-a-build-environment}

`omnibus-gitlab`パッケージをビルドするために必要なビルドツールを含むDockerイメージは、[`GitLab Omnibus Builder`](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)プロジェクトの[Container Registry](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/container_registry)にあります。

1. [Docker Engineをインストール](https://docs.docker.com/engine/install/)。
   - Docker Engineは必須ですが、Docker Desktopは必須ではありません。
   - [Mac用Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)は商用利用の場合、[Dockerサブスクリプションサービス契約](https://www.docker.com/legal/docker-subscription-service-agreement/)に従って有償のサブスクリプションが必要です。代替案を検討してください。

1. パッケージをビルドするOS用のDockerイメージをプルします。`omnibus-gitlab`で正式に使用されているイメージの現在のバージョンは、[CI設定](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml) `BUILDER_IMAGE_REVISION`環境変数で参照されています。

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION}
   ```

1. `omnibus-gitlab`ソースをクローンし、クローンされたディレクトリに変更します:

   ```shell
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   cd ~/omnibus-gitlab
   ```

1. コンテナを起動し、そのシェルに入り、`omnibus-gitlab`ディレクトリをコンテナにマウントします:

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. デフォルトでは、`omnibus-gitlab`は、さまざまなGitLabコンポーネントのソースをフェッチするために、パブリックGitLabリポジトリを選択します。環境変数`ALTERNATIVE_SOURCES`を`false`に設定して、`dev.gitlab.org`からビルドします。

   ```shell
   export ALTERNATIVE_SOURCES=false
   ```

   コンポーネントのソース情報は、[`.custom_sources.yml`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml)ファイルにあります。

1. デフォルトでは、`omnibus-gitlab`コードベースは、CI環境で使用されるように最適化されています。このような最適化の1つは、GitLab CIパイプラインによってビルドされた、事前コンパイル済みのRailsアセットを再利用することです。これをビルドで活用する方法については、[アップストリームアセットのフェッチ](#fetch-upstream-assets)セクションを確認してください。または、`COMPILE_ASSETS`環境変数を設定して、パッケージビルド中にアセットをコンパイルすることもできます。

   ```shell
   export COMPILE_ASSETS=true
   ```

1. デフォルトでは、XZ圧縮を使用して最終的なDEBパッケージが生成されます。これにより、ビルド時間がほとんどまたはまったく増加せず、インストール（解凍）時間がわずかに増加するだけで、Gzipと比較してパッケージサイズが約30％削減されます。ただし、システムのパッケージマネージャーもその形式をサポートしている必要があります。システムのパッケージマネージャーがXZパッケージをサポートしていない場合は、`COMPRESS_XZ`環境変数を`false`に設定します:

   ```shell
   export COMPRESS_XZ=false
   ```

1. ライブラリおよびその他の依存関係をインストールします:

   ```shell
   cd /omnibus-gitlab
   bundle install
   bundle binstubs --all
   ```

### アップストリームアセットのフェッチ {#fetch-upstream-assets}

GitLabおよびGitLab-FOSSプロジェクトのパイプラインは、事前コンパイルされたアセットを含むDockerイメージを作成し、そのイメージをコンテナレジストリに公開します。パッケージをビルドする際に、時間を節約するために、アセットを再度コンパイルする代わりに、これらのイメージを再利用できます:

1. ビルドしているGitLabまたはGitLab-FOSSのrefに対応するアセットDockerイメージをフェッチします。たとえば、最新の`master` refsに対応するアセットイメージをプルするには、次を実行します:

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

1. ビルド環境コンテナの起動中に、その中にアセットディレクトリをマウントします:

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -v ~/gitlab-assets:/gitlab-assets -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. `COMPILE_ASSETS`をtrueに設定する代わりに、アセットが見つかるパスを設定します:

   ```shell
   export ASSET_PATH=/gitlab-assets
   ```

## パッケージをビルドする {#build-the-package}

ビルド環境を準備し、必要な変更を加えたら、提供されているRakeタスクを使用してパッケージをビルドできます:

1. ビルドを機能させるには、Gitワーキングディレクトリがクリーンである必要があります。したがって、変更を新しいブランチにコミットします。

1. Rakeタスクを実行して、パッケージをビルドします:

   ```shell
   bundle exec rake build:project
   ```

パッケージがビルドされ、`~/omnibus-gitlab/pkg`ディレクトリで使用できるようになります。

### EEパッケージをビルドする {#build-an-ee-package}

デフォルトでは、`omnibus-gitlab`はCEパッケージをビルドします。EEパッケージをビルドする場合は、Rakeタスクを実行する前に、`ee`環境変数を設定します:

```shell
export ee=true
```

### ビルド中に作成されたファイルをクリーンアップする {#clean-files-created-during-build}

`omnibus`の`clean`コマンドラインを使用して、ビルドプロセス中に生成されたすべての一時ファイルをクリーンアップできます:

```shell
bin/omnibus clean gitlab
```

`--purge`パージオプションを追加すると、プロジェクトのインストールディレクトリ（`/opt/gitlab`）およびパッケージキャッシュディレクトリ（`/var/cache/omnibus/pkg`）を含め、ビルド中に生成された**すべて**のファイルが削除されます:

```shell
bin/omnibus clean --purge gitlab
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

## Omnibusのヘルプを表示 {#get-help-on-omnibus}

Omnibusコマンドラインインターフェースのヘルプを表示するには、`help`コマンドラインを実行します:

```shell
bin/omnibus help
```

<!-- vale gitlab_base.SubstitutionWarning = YES -->
