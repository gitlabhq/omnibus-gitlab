---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: JiHu Edition
---

{{< alert type="note" >}}

このセクションは、中国市場のお客様のみに関連します。

{{< /alert >}}

GitLabは、JiHuという新しい独立した中国企業にその技術をライセンス供与しました。この独立企業は、中国におけるGitLabの完全なDevOpsプラットフォームの導入を促進し、GitLabコミュニティとオープンソースのコントリビュートを育成するのに役立ちます。

詳細については、[ブログ投稿のお知らせ](https://about.gitlab.com/blog/2021/03/18/gitlab-licensed-technology-to-new-independent-chinese-company/)と[FAQ](https://about.gitlab.com/pricing/faq-jihu/)をご覧ください。

## 前提要件 {#prerequisites}

GitLab JiHu Editionをインストールする前に、システムの[要件](https://docs.gitlab.com/install/requirements/)を確認することが非常に重要です。システム要件には、GitLabをサポートするための最小限のハードウェア、ソフトウェア、データベース、および追加要件に関する詳細が含まれています。

JiHuとの契約後、JiHuの担当者から、インストールプロセスの一部として使用できるライセンスが提供されます。

## JiHu Editionパッケージをインストールまたはアップデートする {#install-or-update-a-jihu-edition-package}

{{< alert type="note" >}}

初めてインストールする場合は、優先するドメイン名を設定するために、`EXTERNAL_URL="<GitLab URL>"`変数を渡す必要があります。インストールにより、そのURLでGitLabが自動的に設定および起動されます。HTTPSを有効にするには、証明書を指定するための[追加の設定](settings/nginx.md#enable-https)が必要です。

{{< /alert >}}

JiHu Editionパッケージのインストールまたはアップデートの詳細については、[GitLab Jihu Edition Install](https://gitlab.cn/install/)ページを参照してください。

### 初期パスワードを設定してライセンスを適用する {#set-initial-password-and-apply-license}

GitLab JiHu Editionを初めてインストールすると、パスワードリセット画面にリダイレクトされます。初期管理者アカウントのパスワードを入力すると、ログイン画面に戻ります。デフォルトアカウントのユーザー名`root`を使用してログインします。

詳細な手順については、[設定とインストール](https://docs.gitlab.com/install/package/)を参照してください。

さらに、サーバーのGitLab管理パネルに移動して、[JiHu Editionライセンスファイルをアップロードできます](https://docs.gitlab.com/administration/license/#uploading-your-license)。

## GitLab Enterprise EditionをJiHu Editionにアップデートする {#update-gitlab-enterprise-edition-to-jihu-edition}

Linuxパッケージを使用してインストールされた既存のGitLab Enterprise Edition（EE）サーバーをGitLab JiHu Edition（JH）にアップデートするには、EEの上にJiHu Edition（JH）パッケージをインストールします。

利用可能なオプションは次のとおりです:

- （推奨）同じバージョンのEEからJHにアップデートします。
- サポートされている[アップグレードパス](https://docs.gitlab.com/update/#upgrade-paths)である場合（たとえば、EE 13.5.4からJH 13.10.0）、EEの低いバージョンからJHの高いバージョンにアップデートします。

以下の手順では、同じバージョン（たとえば、EE 13.10.0からJH 13.10.0）をアップデートすることを前提としています。

EEをJHにアップデートするには:

- deb/rpmパッケージを使用してGitLabをインストールした場合:

  1. [バックアップ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)を作成します。
  1. 現在インストールされているGitLabのバージョンを検索します:

     - Debian/Ubuntuの場合:

       ```shell
       sudo apt-cache policy gitlab-ee | grep Installed
       ```

       出力は`Installed: 13.10.0-ee.0`のようになります。したがって、インストールされているバージョンは`13.10.0-ee.0`です。

     - CentOS/RHELの場合:

       ```shell
       sudo rpm -q gitlab-ee
       ```

       出力は`gitlab-ee-13.10.0-ee.0.el8.x86_64`のようになります。したがって、インストールされているバージョンは`13.10.0-ee.0`です。

  1. オペレーティングシステム用の[JiHu Editionパッケージのインストール](#install-or-update-a-jihu-edition-package)時と同じ手順に従い、前の手順で説明したバージョンと同じバージョンを選択してください。`<url>`をパッケージのURLに置き換えます。

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. サーバーのGitLab管理パネル（`/admin/license/new`）に移動し、JiHu Editionライセンスファイルをアップロードします。JiHuにアップデートする前にEEライセンスが既にインストールされている場合、JHがインストールされるとEEライセンスは自動的に無効になります。

  1. GitLabが期待どおりに動作していることを確認してから、古いEnterprise Editionリポジトリを削除します:

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

  1. [Dockerアップデートガイド](https://docs.gitlab.com/install/docker/)に従い、`gitlab/gitlab-ee:latest`を以下に置き換えます:

     ```shell
     registry.gitlab.com/gitlab-jh/omnibus-gitlab/gitlab-jh:<version>
     ```

     `<version>`は現在インストールされているGitLabのバージョンであり、次の方法で確認できます:

     ```shell
     sudo docker ps | grep gitlab/gitlab-ee | awk '{print $2}'
     ```

     出力は`gitlab/gitlab-ee:13.10.0-ee.0`のようになります。したがって、この場合、`<version>`は`13.10.0`と等しくなります。

  1. サーバーのGitLab管理パネル（`/admin/license/new`）に移動し、JiHu Editionライセンスファイルをアップロードします。JiHuにアップデートする前にEEライセンスが既にインストールされている場合、JHがインストールされるとEEライセンスは自動的に無効になります。

以上です。GitLab JiHu Editionを使用できるようになりました！新しいバージョンにアップデートするには、[JiHuパッケージのインストールまたはアップデート](#install-or-update-a-jihu-edition-package)を参照してください。

## GitLab Enterprise Editionに戻る {#go-back-to-gitlab-enterprise-edition}

JiHu EditionのインストールをダウングレードしてGitLab Enterprise Edition（EE）にするには、現在インストールされているパッケージの上に同じバージョンのEnterprise Editionパッケージをインストールします。

GitLab EEの推奨インストール方法に応じて、次のいずれかを行います:

- 公式のGitLabパッケージリポジトリを使用して[GitLab EEをインストール](https://about.gitlab.com/install/?version=ee)します。
- GitLab EEパッケージをダウンロードし、[手動でインストールします](https://docs.gitlab.com/update/package/#upgrade-using-a-manually-downloaded-package)。
