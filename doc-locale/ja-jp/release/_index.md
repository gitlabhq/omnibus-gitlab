---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Omnibus GitLabのリリースプロセス
---

私たちの主な目標は、どのバージョンのGitLabがLinuxパッケージに含まれているかを明確にすることです。

## 公式Linuxパッケージはどのようにビルドされますか {#how-is-the-official-linux-package-built}

公式パッケージビルドは、GitLab Inc.によって完全に自動化されています。

2種類のビルドを区別できます:

- <https://packages.gitlab.com>へのリリース用パッケージ。
- S3バケットで利用可能なブランチからビルドされたテストパッケージ。

どちらのタイプも同じインフラストラクチャ上にビルドされます。

## インフラストラクチャ {#infrastructure}

各パッケージは、対象とするプラットフォーム上にビルドされます（CentOS 6パッケージはCentOS6サーバー、Debian 8パッケージはDebian 8サーバーというように）。ビルドサーバーの数は異なりますが、プラットフォームごとに少なくとも1つのビルドサーバーが常に存在します。

`omnibus-gitlab`プロジェクトは、GitLab CI/CDをフル活用しています。これは、`omnibus-gitlab`リポジトリへの各プッシュがGitLab CI/CDでビルドをトリガーし、パッケージを作成することを意味します。

GitLab.comはLinuxパッケージを使用してデプロイしているため、GitLab.comに問題が発生した場合や、パッケージのセキュリティリリースが原因で、パッケージをビルドするための個別のリモートが必要です。

このリモートは`https://dev.gitlab.org`にあります。`omnibus-gitlab`プロジェクト (`https://dev.gitlab.org`) と他のパブリックリモートとの唯一の違いは、プロジェクトがアクティブなGitLab CIを持ち、ビルドサーバー上で実行されるプロジェクトに特定のRunnerが割り当てられていることです。これはすべてのGitLabコンポーネントにも当てはまります。例えば、GitLabシェルは`https://dev.gitlab.org`でもGitLab.comとまったく同じです。

すべてのビルドサーバーは[GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)を実行し、すべてのRunnerはデプロイキーを使用して`https://dev.gitlab.org`のプロジェクトに接続します。ビルドサーバーは、<https://packages.gitlab.com>の公式パッケージリポジトリと、テストパッケージを格納する特別なAmazon S3バケットにもアクセスできます。

## ビルドプロセス {#build-process}

GitLab Incは、すべてのリリースのリリースタスクを自動化するために[release-tools project](https://gitlab.com/gitlab-org/release-tools/tree/master)を使用しています。リリースマネージャーがリリースプロセスを開始すると、いくつかの重要なことが行われます:

1. プロジェクトのすべてのリモートが同期されます。
1. コンポーネントのバージョンはGitLab CE/EEリポジトリ（例: `VERSION`、`GITLAB_SHELL_VERSION`）から読み取り、`omnibus-gitlab`リポジトリに書き込まれます。
1. 特定のGitタグが作成され、`omnibus-gitlab`リポジトリに同期されます。

`omnibus-gitlab`リポジトリ（`https://dev.gitlab.org`）が更新されると、GitLab CIビルドがトリガーされます。

具体的な手順は、`.gitlab-ci.yml` `omnibus-gitlab`リポジトリのファイルに記載されています。ビルドは、すべてのプラットフォームで同時に実行されます。

ビルド中、`omnibus-gitlab`はソースロケーションから外部ライブラリをプルし、GitLab、GitLabシェル、GitLab WorkhorseなどのGitLabコンポーネントは`https://dev.gitlab.org`からプルされます。

ビルドが完了し、.debまたは.rpmパッケージがビルドされると、ビルドタイプのパッケージに応じて、<https://packages.gitlab.com>または一時的なS3バケット（30日以上前のファイルはパージされます）にプッシュされます。

## コンポーネントバージョンを手動で指定する {#specifying-component-versions-manually}

### 開発マシン上 {#on-your-development-machine}

1. パッケージ化するGitLabのタグを選択します（例: `v6.6.0`）。
1. `omnibus-gitlab`リポジトリにリリースブランチを作成します（例: `6-6-stable`）。
1. リリースブランチが既に存在する場合（たとえば、パッチリリースを実行している場合）、ローカルマシンに最新の変更をプルするようにしてください:

   ```shell
   git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # existing release branch
   ```

1. `support/set-revisions`を使用して、`config/software/`のファイルのリビジョンを設定します。Git SHA1のタグ名を調べて、ダウンロードソースを`https://dev.gitlab.org`に設定します。EEリリースには`set-revisions --ee`を使用します:

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

1. GitLabタグに対応する`omnibus-gitlab`に注釈付きタグを作成します。`omnibus-gitlab`タグは、`MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`のようになります。`MAJOR.MINOR.PATCH`はGitLabのバージョン、`OTHER`は`ce`、`ee`、`rc1`（または`rc1.ee`）のようになり、`OMNIBUS_RELEASE`は数値（0から始まる）です:

   ```shell
   git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
   ```

   {{< alert type="warning" >}}

   `omnibus-gitlab`タグには、ハイフン`-`をどこにも使用しないでください。

   {{< /alert >}}

   アップストリームタグを`omnibus-gitlab`タグシーケンスに変換する例:

   | アップストリームタグ     | `omnibus-gitlab`タグシーケンス               |
   | ------------     | --------------------                        |
   | `v7.10.4`        | `7.10.4+ce.0`、`7.10.4+ce.1`、`...`         |
   | `v7.10.4-ee`     | `7.10.4+ee.0`、`7.10.4+ee.1`、`...`         |
   | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`、`7.11.0+rc1.ee.1`、`...` |

1. ブランチとタグを`https://gitlab.com`と`https://dev.gitlab.org`の両方にプッシュします:

   ```shell
   git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   ```

   注釈付きタグを`https://dev.gitlab.org`にプッシュすると、パッケージリリースがトリガーされます。

### パッケージの公開 {#publishing-the-packages}

`https://dev.gitlab.org/gitlab/omnibus-gitlab/builds`でパッケージのビルドの進捗状況を追跡できます。これらは、ビルドの成功後に自動的に[Packagecloud repositories](https://packages.gitlab.com/gitlab/)にプッシュされます。

### クラウドイメージの更新 {#updating-cloud-images}

クラウドイメージのリリースプロセスについては、<https://handbook.gitlab.com/handbook/alliances/cloud-images/>に記載されています。

新しいイメージは、次の場合にリリースされます:

1. GitLabの新しい月次リリースがある場合。
1. セキュリティ脆弱性がパッチリリースで修正された場合。
1. イメージに影響を与える重大なイシューを修正するパッチがある。

新しいイメージは、パッケージリリースから3営業日以内にリリースする必要があります。

イメージ固有のリリースに関するドキュメント:

- （**非推奨**）[OpenShift](https://docs.gitlab.com/charts/development/release/)。
