---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージの署名
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

当社は、<https://packages.gitlab.com>で提供する様々なOSパッケージを共有するためのパッケージホスティングシステムを維持しています。

このインスタンスは、これらのパッケージの整合性を確保するために様々な暗号学的なメソッドを使用しています。

## パッケージリポジトリのメタデータ署名キー {#package-repository-metadata-signing-key}

APTおよびYUMリポジトリは、メタデータに署名するためにGPGキーを使用します。このキーは、インストール手順で指定されたリポジトリセットアップスクリプトによって自動的にインストールされます。

### 現在のリポジトリ署名キー {#current-repository-signing-key}

以下のキーは、リポジトリメタデータに署名するために使用されます。

| キー属性 | 値 |
|:--------------|:------|
| 名前          | `GitLab B.V.` |
| メール         | `packages@gitlab.com` |
| コメント       | `package repository signing key` |
| フィンガープリント   | `F640 3F65 44A3 8863 DAA0 B6E0 3F01 618A 5131 2F3F` |
| 有効期限        | `2028-02-06` |
| ダウンロード場所 | `https://packages.gitlab.com/gpgkey/gpg.key` |

- **2020-04-06**から有効。
- 有効期限が**2024-03-01**から**2026-02-27**に延長されました。
- 有効期限が**2026-02-27**から**2028-02-06**に延長されました。

キーの有効期限が切れているというエラーが表示された場合、最新のリポジトリ署名キーを[フェッチする](#fetch-the-latest-repository-signing-key)必要があります。

### 最新のリポジトリ署名キーをフェッチする {#fetch-the-latest-repository-signing-key}

最新のリポジトリ署名キーをフェッチするには:

{{< tabs >}}

{{< tab title="Debian/Ubuntu/Raspbian" >}}

1. キーをダウンロード:

   ```shell
   sudo mkdir -p /etc/apt/keyrings
   sudo curl --fail --silent --show-error \
        --output /etc/apt/keyrings/gitlab-keyring.asc \
        --url "https://packages.gitlab.com/gpgkey/gpg.key"
   ```

1. お使いのリポジトリソースファイルを更新して、キーを参照するようにします。`/etc/apt/sources.list.d/gitlab_gitlab-ee.list` (または`gitlab_gitlab-ce.list`) を編集し、`deb`の後に`[signed-by=/etc/apt/keyrings/gitlab-keyring.asc]`を追加します:

   ```plaintext
   deb [signed-by=/etc/apt/keyrings/gitlab-keyring.asc] https://packages.gitlab.com/gitlab/gitlab-ee/<os>/<codename> <codename> main
   deb-src [signed-by=/etc/apt/keyrings/gitlab-keyring.asc] https://packages.gitlab.com/gitlab/gitlab-ee/<os>/<codename> <codename> main
   ```

> [!note]
> `apt-key`の使用は[非推奨](https://blog.packagecloud.io/secure-solutions-for-apt-key-add-deprecated-messages/)となり、Debian 13で削除されました。
>
> `apt-key`を使用していて、`signed-by`メソッドに移行することができない場合（ソースリストファイルに`signed-by`が含まれていない場合は`apt-key`を使用しています）、GitLabリポジトリの公開キーを更新するために、rootとして以下を実行します:
>
> ```shell
> curl -s "https://packages.gitlab.com/gpgkey/gpg.key" | apt-key add -
> apt-key list 3F01618A51312F3F
> ```

{{< /tab >}}

{{< tab title="CentOS/OpenSUSE/SUSE Linux Enterprise Server" >}}

1. [`repo_gpgcheck`がアクティブであることを確認](#verify-if-signature-check-is-active)します。
1. 現在インストールされているキーのリストを取得し、削除します:

   ```shell
   rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n' | grep -i gitlab | xargs sudo rpm -e
   ```

1. dnfキャッシュをパージします:

   ```shell
   sudo rm -rf /var/cache/dnf
   ```

1. GitLabパッケージリポジトリを[再度追加](https://docs.gitlab.com/install/package/almalinux/#add-the-gitlab-package-repository)します。
1. キャッシュを再構築します:

   ```shell
   sudo dnf makecache
   ```

{{< /tab >}}

{{< /tabs >}}

### 以前のリポジトリ署名キー {#previous-repository-signing-keys}

以下のキーは、リポジトリメタデータに署名するために使用されていましたが、現在は期限切れです。

| シリアル番号 | キーID                                               | 有効期限 |
|:--------|:-----------------------------------------------------|:------------|
| 1       | `1A4C 919D B987 D435 9396  38B9 1421 9A96 E15E 78F4` | `2020-04-15` |

## パッケージ署名の検証 {#package-signature-verification}

GitLabが生成したパッケージの署名を、手動およびサポートされている場合は自動で検証できます。

### 現在のパッケージ署名キー {#current-package-signing-key}

以下のキーは、リポジトリメタデータに署名するために使用されます。

| キー属性 | 値 |
|---------------|-------|
| 名前          | `GitLab, Inc.` |
| メール         | `support@gitlab.com` |
| フィンガープリント   | `98BF DB87 FCF1 0076 416C 1E0B AD99 7ACC 82DD 593D` |
| 有効期限        | `2028-02-16` |
| ダウンロード場所 | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg` |

### 以前のパッケージ署名キー {#previous-package-signing-keys}

| シリアル番号 | キーID                                              | 失効日 | 有効期限  | ダウンロード場所 |
|---------|-----------------------------------------------------|-----------------|--------------|-------------------|
| 1       | `9E71 648F 3A35 EA00 CAE4 43E7 1155 1132 6BA7 34DA` | `2025-02-14`    | `2025-07-01` | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-3D645A26AB9FBD22.pub.gpg` |

### RPMベースのディストリビューション {#rpm-based-distributions}

RPM形式には、GPG署名機能が完全に実装されており、その形式に基づいたパッケージ管理システムと完全に統合されています。

#### GitLabの公開キーが存在することを確認 {#verify-gitlab-public-key-is-present}

RPMベースのLinuxディストリビューションでパッケージを検証するには、GitLab, Inc.の公開キーが`rpm`キーチェーンに存在することを確認してください。例: 

```shell
rpm -q gpg-pubkey-98bfdb87fcf10076416c1e0bad997acc82dd593d-67aefdd8 --qf '%{name}-%{version}-%{release} --> %{summary}'
```

このコマンドは以下を出力します:

- 公開キーに関する情報。
- キーがインストールされていないというメッセージ。例: `gpg-pubkey-f27eab47-60d4a67e is not installed`。

キーが存在しない場合は、インポートします。例: 

```shell
rpm --import https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
```

#### 署名チェックがアクティブであるかを確認 {#verify-if-signature-check-is-active}

既存のインストールでパッケージの署名チェックがアクティブであるかを確認するには、リポジトリファイルの内容を比較します:

1. リポジトリファイルが存在するか確認します: `file /etc/yum.repos.d/gitlab_gitlab-*.repo`。
1. 署名チェックがアクティブであることを確認します: `grep gpgcheck /etc/yum.repos.d/gitlab_gitlab-*.repo`。このコマンドの出力は次のようになるはずです:

   ```plaintext
   repo_gpgcheck=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgcheck=1
   ```

   または

   ```plaintext
   repo_gpgcheck=1
   pkg_gpgcheck=1
   repo_gpgcheck=1
   pkg_gpgcheck=1
   ```

ファイルが存在しない場合、リポジトリはインストールされていません。ファイルは存在するが、出力に`gpgpcheck=0`と表示される場合、その値を編集して有効にする必要があります。

#### Linuxパッケージの`rpm`ファイルを検証する {#verify-a-linux-package-rpm-file}

公開キーが存在することを確認した後、パッケージを検証します:

```shell
rpm --checksig gitlab-xxx.rpm
```

### Debianベースのディストリビューション {#debian-based-distributions}

Debianパッケージ形式には、パッケージに署名するための公式な方法が含まれていません。当社は`debsig`標準を実装しましたが、これはよく文書化されていますが、ほとんどのディストリビューションではデフォルトで有効になっていません。

Linuxパッケージの`deb`ファイルは、以下のいずれかの方法で検証できます:

- 必要な`debsigs`ポリシーとキーリングを設定した後、`debsig-verify`を使用します。
- GnuPGで含まれている`_gpgorigin`ファイルを手動で確認します。

#### `debsigs`を設定する {#configure-debsigs}

`debsigs`のポリシーとキーリングの設定は複雑になる可能性があるため、設定用の`gitlab-debsigs.sh`スクリプトを提供しています。このスクリプトを使用するには、公開キーとスクリプトをダウンロードする必要があります。

```shell
curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
curl -JLO "https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/scripts/gitlab-debsigs.sh"
chmod +x gitlab-debsigs.sh
sudo ./gitlab-debsigs.sh CB947AD886C8E8FD.pub.gpg
```

#### `debsig-verify`で検証する {#verify-with-debsig-verify}

`debsig-verify`を使用するには:

1. [`debsigs`を設定](#configure-debsigs)します。
1. `debsig-verify`パッケージをインストールします。
1. `debsig-verify`を実行してファイルを検証します:

   ```shell
   debsig-verify gitlab-xxx.deb
   ```

#### GnuPGで検証する {#verify-with-gnupg}

`debsig-verify`によってインストールされた依存関係をインストールしたくない場合は、代わりにGnuPGを使用できます:

1. パッケージ署名公開キーをダウンロードしてインポートします:

   ```shell
   curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
   gpg --import CB947AD886C8E8FD.pub.gpg
   ```

1. 署名ファイル`_gpgorigin`を抽出します:

   ```shell
   ar x gitlab-xxx.deb _gpgorigin
   ```

1. 署名が内容と一致することを確認します:

   ```shell
   ar p gitlab-xxx.deb debian-binary control.tar.xz data.tar.xz | gpg --verify _gpgorigin -
   ```

   このコマンドの出力は次のようになります:

   ```shell
   gpg: Signature made Wed Feb 18 18:07:22 2026 UTC
   gpg:                using RSA key 98BFDB87FCF10076416C1E0BAD997ACC82DD593D
   gpg:                issuer "support@gitlab.com"
   gpg: Good signature from "GitLab, Inc. <support@gitlab.com>" [unknown]
   Primary key fingerprint: 98BF DB87 FCF1 0076 416C  1E0B AD99 7ACC 82DD 593D
   ```

検証が`gpg: BAD signature from "GitLab, Inc. <support@gitlab.com>" [unknown]`で失敗した場合は、以下を確認してください:

- ファイル名が正しい順序で記述されていること。
- ファイル名がアーカイブの内容と一致すること。

使用しているLinuxディストリビューションによっては、アーカイブの内容のサフィックスが異なる場合があります。これは、コマンドを適切に調整する必要があることを意味します。アーカイブの内容を確認するには、`ar t gitlab-xxx.deb`を実行します。

例えば、Ubuntu Focal (20.04) の場合:

```shell
$ ar t gitlab-ee_17.4.2-ee.0_amd64.deb
debian-binary
control.tar.xz
data.tar.xz
_gpgorigin
```
