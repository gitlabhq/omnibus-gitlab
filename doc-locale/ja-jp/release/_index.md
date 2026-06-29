---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Omnibus GitLabリリースプロセス
---

私たちの主な目標は、LinuxパッケージにどのバージョンのGitLabが含まれているかを明確にすることです。

## 公式Linuxパッケージはどのように構築されていますか {#how-is-the-official-linux-package-built}

公式パッケージのビルドは、GitLab Inc.によって完全に自動化されています。

2種類のビルドを区別できます:

- <https://packages.gitlab.com>へのリリース用のパッケージ。
- ブランチからビルドされたテストパッケージ。S3バケットで利用可能です。

どちらのタイプも同じインフラストラクチャ上にビルドされます。

## インフラストラクチャ {#infrastructure}

各パッケージは、対象となるプラットフォーム上でビルドされます（CentOS 6パッケージはCentOS6サーバー上でビルドされ、Debian 8パッケージはDebian 8サーバー上でビルドされるなど）。ビルドサーバーの数は異なりますが、プラットフォームごとに少なくとも1つのビルドサーバーが常に存在します。

`omnibus-gitlab`プロジェクトはGitLab CI/CDを完全に利用しています。つまり、`omnibus-gitlab`リポジトリへのプッシュごとにGitLab CI/CDでビルドがトリガーされ、パッケージが作成されます。

Linuxパッケージを使用してGitLab.comをデプロイしているため、GitLab.comに問題がある場合、またはセキュリティリリースのパッケージの場合は、パッケージをビルドするための別のリモートが必要です。

このリモートは`https://dev.gitlab.org`にあります。`omnibus-gitlab`プロジェクトと`https://dev.gitlab.org`上の他の公開リモートとの唯一の違いは、そのプロジェクトがアクティブなGitLab CIを持ち、ビルドサーバーで実行される特定のRunnerがプロジェクトに割り当てられていることです。これはすべてのGitLabコンポーネントにも当てはまります。GitLab Shellは、GitLab.com上にあるものと`https://dev.gitlab.org`上にあるものがまったく同じです。

すべてのビルドサーバーは[GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)を実行し、すべてのRunnerは`https://dev.gitlab.org`上のプロジェクトに接続するためにデプロイキーを使用します。ビルドサーバーは、<https://packages.gitlab.com>の公式パッケージリポジトリと、テストパッケージを保存する特別なAmazon S3バケットにもアクセスできます。

## ビルドプロセス {#build-process}

GitLab, Inc.は、各リリースのリリースタスクを自動化するために[release-tools project](https://gitlab.com/gitlab-org/release-tools/tree/master)を使用しています。リリースマネージャーがリリースプロセスを開始すると、いくつかの重要なタスクが実行されます:

1. プロジェクトのすべてのリモートが同期されます。
1. コンポーネントのバージョンはGitLab CE/EEリポジトリから読み取られ（例: `VERSION`、`GITLAB_SHELL_VERSION`）、`omnibus-gitlab`リポジトリに書き込まれます。
1. 特定のGitタグが作成され、`omnibus-gitlab`リポジトリに同期されます。

`omnibus-gitlab`リポジトリが`https://dev.gitlab.org`で更新されると、GitLab CIビルドがトリガーされます。

具体的な手順は、`omnibus-gitlab`リポジトリの`.gitlab-ci.yml`ファイルで確認できます。ビルドはすべてのプラットフォームで同時に実行されます。

ビルド中、`omnibus-gitlab`は外部ライブラリをソースの場所からプルし、GitLab、GitLab Shell、GitLab WorkhorseなどのGitLabコンポーネントは`https://dev.gitlab.org`からプルされます。

ビルドが完了し、.debまたは.rpmパッケージがビルドされると、ビルドタイプに応じてパッケージは<https://packages.gitlab.com>または一時的な（30日以上前のファイルはパージされます）S3バケットにプッシュされます。

## コンポーネントのバージョンを手動で指定する {#specifying-component-versions-manually}

### 開発マシン上での設定 {#on-your-development-machine}

1. GitLabのタグを選択してパッケージ化します（例: `v6.6.0`）。
1. ご自身の`omnibus-gitlab`リポジトリにリリースブランチを作成します（例: `6-6-stable`）。
1. 例えば、パッチリリースを行っているためにリリースブランチが既に存在する場合は、最新の変更をローカルマシンにプルしてください:

   ```shell
   git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # existing release branch
   ```

1. `support/set-revisions`を使用して、`config/software/`内のファイルの改訂を設定します。タグ名を取得してGit SHA1を検索し、ダウンロードソースを`https://dev.gitlab.org`に設定します。EEリリースには`set-revisions --ee`を使用します:

   ```shell
   # usage: set-revisions [--ee] GITLAB_RAILS_REF GITLAB_SHELL_REF GITALY_REF GITLAB_ELASTICSEARCH_INDEXER_REF

   # For GitLab CE:
   support/set-revisions v1.2.3 v1.2.3 1.2.3 1.2.3 1.2.3

   # For GitLab EE:
   support/set-revisions --ee v1.2.3-ee v1.2.3 1.2.3 1.2.3 1.2.3
   ```

1. 新しいバージョンをリリースブランチにコミットします:

   ```shell
   git add VERSION GITLAB_SHELL_VERSION GITALY_SERVER_VERSION
   git commit
   ```

1. GitLabタグに対応する`omnibus-gitlab`に注釈付きタグを作成します。`omnibus-gitlab`タグは次のようになります: `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`。ここで`MAJOR.MINOR.PATCH`はGitLabバージョン、`OTHER`は`ce`、`ee`または`rc1`（または`rc1.ee`）のようなもので、`OMNIBUS_RELEASE`は数字（0から始まる）です:

   ```shell
   git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
   ```

   > [!warning]
   > `omnibus-gitlab`タグのどこにもハイフン`-`を使用しないでください。

   アップストリームタグを`omnibus-gitlab`タグシーケンスに変換する例:

   | アップストリームタグ     | `omnibus-gitlab`タグシーケンス               |
   | ------------     | --------------------                        |
   | `v7.10.4`        | `7.10.4+ce.0`、`7.10.4+ce.1`、`...`         |
   | `v7.10.4-ee`     | `7.10.4+ee.0`、`7.10.4+ee.1`、`...`         |
   | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`、`7.11.0+rc1.ee.1`、`...` |

1. ブランチとタグの両方を`https://gitlab.com`と`https://dev.gitlab.org`にプッシュします:

   ```shell
   git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   ```

   `https://dev.gitlab.org`に注釈付きタグをプッシュすると、パッケージリリースがトリガーされます。

### パッケージを公開する {#publishing-the-packages}

`https://dev.gitlab.org/gitlab/omnibus-gitlab/builds`でパッケージのビルドの進行状況を追跡することができます。成功したビルドの後、それらは自動的に弊社の[`packages.gitlab.com`リポジトリ](https://packages.gitlab.com/gitlab/)にプッシュされます。

### クラウドイメージの更新 {#updating-cloud-images}

新しいイメージは以下のときにリリースされます:

1. GitLabの月次リリースが新しい場合。
1. セキュリティ脆弱性がパッチリリースで修正された場合。
1. イメージに影響を与える重大な問題を修正するパッチがある場合。

新しいイメージは、パッケージリリースから3営業日以内にリリースされるべきです。

イメージ固有のリリースドキュメント:

- (**非推奨**) [OpenShift](https://docs.gitlab.com/charts/development/release/)。
