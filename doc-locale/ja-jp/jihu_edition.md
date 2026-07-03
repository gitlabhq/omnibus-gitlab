---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: JiHu Edition
---

> [!note]
> このセクションは、中国市場の顧客である場合にのみ関連します。

GitLabは、その技術をJiHuと呼ばれる新しい独立した中国企業にライセンス供与しました。この独立した会社は、中国におけるGitLabの完全なDevOpsプラットフォームの導入を促進し、GitLabコミュニティとオープンソースへのコントリビュートを育成するのに役立ちます。

詳細については、[ブログ投稿の発表](https://about.gitlab.com/blog/gitlab-licensed-technology-to-new-independent-chinese-company/)と[FAQ](https://about.gitlab.com/pricing/faq-jihu/)を参照してください。

## 前提条件 {#prerequisites}

GitLab JiHu Editionをインストールする前に、システムの[要件](https://docs.gitlab.com/install/requirements/)を確認することが非常に重要です。システム要件には、GitLabをサポートするための最小限のハードウェア、ソフトウェア、データベース、および追加要件に関する詳細が含まれています。

JiHuと契約後、JiHuの担当者からインストールプロセスの一部として使用できるライセンスが提供されます。

## JiHu Editionパッケージをインストールまたは更新する {#install-or-update-a-jihu-edition-package}

> [!note]
> 初めてインストールする場合は、希望のドメイン名を設定するために`EXTERNAL_URL="<GitLab URL>"`変数を渡す必要があります。インストールにより、そのURLでGitLabが自動的に設定および起動されます。HTTPSを有効にするには、証明書を指定するために[追加の設定](settings/nginx.md#enable-https)が必要です。

JiHu Editionパッケージのインストールまたは更新の詳細については、[GitLab JiHu Editionインストール](https://gitlab.cn/install)ページを参照してください。

### 初期パスワードを設定し、ライセンスを適用する {#set-initial-password-and-apply-license}

GitLab JiHu Editionが初めてインストールされると、パスワードリセット画面にリダイレクトされます。初期管理者アカウントのパスワードを入力すると、ログイン画面に戻ります。デフォルトアカウントのユーザー名`root`を使用してログインします。

詳細な手順については、[インストールと設定](https://docs.gitlab.com/install/package/)を参照してください。

さらに、サーバーのGitLab管理パネルに移動して、[JiHu Editionライセンスファイルをアップロードする](https://docs.gitlab.com/administration/license/#uploading-your-license)ことができます。

## GitLab Enterprise EditionをJiHu Editionに更新する {#update-gitlab-enterprise-edition-to-jihu-edition}

既存のGitLab Enterprise Edition（EE）サーバーをLinuxパッケージを使用してインストールされている場合、GitLab JiHu Edition（JH）に更新するには、EEの上にJiHu Edition（JH）パッケージをインストールします。

利用可能なオプションは次のとおりです:

- （推奨）EEの同じバージョンからJHに更新する。
- EEの低いバージョンからJHの高いバージョンへの更新（サポートされている[アップグレードパス](https://docs.gitlab.com/update/#upgrade-paths)である場合）。例：EE 13.5.4からJH 13.10.0。

次のステップでは、同じバージョン（例：EE 13.10.0からJH 13.10.0）を更新していると仮定します。

EEをJHに更新するには:

- deb/rpmパッケージを使用してGitLabをインストールした場合:

  1. [バックアップ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)を作成します。
  1. 現在インストールされているGitLabのバージョンを見つける:

     - Debian/Ubuntuの場合:

       ```shell
       sudo apt-cache policy gitlab-ee | grep Installed
       ```

       出力は`Installed: 13.10.0-ee.0`に似ているはずです。したがって、インストールされているバージョンは`13.10.0-ee.0`です。

     - CentOS/RHELの場合:

       ```shell
       sudo rpm -q gitlab-ee
       ```

       出力は`gitlab-ee-13.10.0-ee.0.el8.x86_64`に似ているはずです。したがって、インストールされているバージョンは`13.10.0-ee.0`です。

  1. オペレーティングシステムに[JiHu Editionパッケージをインストールする](#install-or-update-a-jihu-edition-package)場合と同じ手順に従い、前のステップで記録したのと同じバージョンを選択してください。`<url>`をパッケージのURLに置き換えます。

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. サーバーのGitLab管理パネル（`/admin/license/new`）に移動し、JiHu Editionライセンスファイルをアップロードします。JiHuに更新する前にEEライセンスがすでにインストールされている場合、JHがインストールされるとEEライセンスは自動的に無効になります。

  1. GitLabが正常に動作していることを確認し、古いEnterprise Editionリポジトリを削除します:

     - Debian/Ubuntuの場合:

       ```shell
       sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ee.list
       ```

     - CentOS/RHELの場合:

       ```shell
       sudo rm /etc/yum.repos.d/gitlab_gitlab-ee.repo
       sudo dnf config-manager --disable gitlab_gitlab-ee
       ```

- Dockerを使用してGitLabをインストールした場合:

  1. [Docker更新ガイド](https://docs.gitlab.com/install/docker/)に従い、`gitlab/gitlab-ee:latest`を次のように置き換えます:

     ```shell
     registry.gitlab.com/gitlab-jh/omnibus-gitlab/gitlab-jh:<version>
     ```

     ここで`<version>`は、現在インストールされているGitLabのバージョンであり、次のコマンドで見つけることができます:

     ```shell
     sudo docker ps | grep gitlab/gitlab-ee | awk '{print $2}'
     ```

     出力は`gitlab/gitlab-ee:13.10.0-ee.0`に似ているはずです。この場合、`<version>`は`13.10.0`に等しくなります。

  1. サーバーのGitLab管理パネル（`/admin/license/new`）に移動し、JiHu Editionライセンスファイルをアップロードします。JiHuに更新する前にEEライセンスがすでにインストールされている場合、JHがインストールされるとEEライセンスは自動的に無効になります。

以上です。これでGitLab JiHu Editionを使用できます！新しいバージョンに更新するには、[JiHuパッケージのインストールまたは更新](#install-or-update-a-jihu-edition-package)を参照してください。

## GitLab Enterprise Editionに戻る {#go-back-to-gitlab-enterprise-edition}

JiHu EditionのインストールをGitLab Enterprise Edition（EE）にダウングレードするには、現在インストールされているバージョンの上にEnterprise Editionの同じパッケージをインストールします。

GitLab EEの優先インストール方法に応じて、次のいずれかです:

- 公式のGitLabパッケージリポジトリを使用し、[GitLab EEをインストール](https://about.gitlab.com/install/?version=ee)します。
- GitLab EEパッケージをダウンロードし、[手動でインストール](https://docs.gitlab.com/update/package/#upgrade-with-a-downloaded-package)します。
