---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージの署名
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

弊社では、さまざまなOSパッケージを共有するために、<https://packages.gitlab.com>の[Packagecloud](https://packagecloud.io)インスタンスを使用しています。

このインスタンスは、さまざまな暗号学的な方法を使用して、これらのパッケージの整合性を確保しています。

## パッケージリポジトリのメタデータ署名キー {#package-repository-metadata-signing-keys}

パッケージクラウドインスタンス上のAPTおよびYUMリポジトリは、GPGキーを使用してメタデータに署名します。このキーは、インストール手順で指定されたリポジトリセットアップスクリプトによって自動的にインストールされます。

### 現在の署名キー {#current-signing-key}

| キーの属性 | 値 |
|:--------------|:------|
| 名前          | `GitLab B.V.` |
| メール         | `packages@gitlab.com` |
| コメント       | `package repository signing key` |
| フィンガープリント   | `F640 3F65 44A3 8863 DAA0 B6E0 3F01 618A 5131 2F3F` |
| 有効期限        | `2026-02-27` |

このキーは**2020-04-06**から有効です。

このキーの有効期限は、**2024-03-01**から**2026-02-27**に延長されました。`2024-03-01`の有効期限が発生した場合は、以下の手順に従ってください。

{{< tabs >}}

{{< tab title="Debianベースのディストリビューション" >}}

パッケージクラウドは`apt-key`を使用しましたが、[これは非推奨です](https://blog.packagecloud.io/secure-solutions-for-apt-key-add-deprecated-messages/)。[TurnKey Linux](https://www.turnkeylinux.org/)など、一部のLinuxディストリビューションから手動でインストールまたは設定されたリポジトリは、Debianパッケージソースリストの`signed-by`サポートをすでに使用しています。

1. `apt-key`または`signed-by`を使用しているかどうかを判断します:

   ```shell
   grep 'deb \[signed-by=' /etc/apt/sources.list.d/gitlab_gitlab-?e.list
   ```

   このコマンドを実行した場合:

   - 行が返された場合は、`apt-key`よりも優先される`signed-by`を使用しています。
   - 行がない場合は、`apt-key`を使用しています。

1. `signed-by`を使用している場合は、このスクリプトをrootとして実行して、GitLabリポジトリの公開キーを更新します:

   ```shell
   awk '/deb \[signed-by=/{
         pubkey = $2;
         sub(/\[signed-by=/, "", pubkey);
         sub(/\]$/, "", pubkey);
         print pubkey
       }' /etc/apt/sources.list.d/gitlab_gitlab-?e.list | \
     while read line; do
       curl -s "https://packages.gitlab.com/gpg.key" | gpg --dearmor > $line
     done
   ```

1. `apt-key`を使用している場合は、このスクリプトをrootとして実行して、GitLabリポジトリの公開キーを更新します:

   ```shell
   apt-key del 3F01618A51312F3F
   curl -s "https://packages.gitlab.com/gpg.key" | apt-key add -
   apt-key list 3F01618A51312F3F
   ```

{{< /tab >}}

{{< tab title="RPMベースのディストリビューション" >}}

YUMとDNFにはわずかな違いがありますが、基盤となる設定は同じです:

1. リポジトリキーリングから既存のキーを削除します:

   ```shell
   for pubring in /var/cache/dnf/*gitlab*/pubring
   do
     gpg --homedir $pubring --delete-key F6403F6544A38863DAA0B6E03F01618A51312F3F
   done
   ```

1. キーの確認を求めるリポジトリデータとキャッシュを更新します:

   ```shell
   dnf check-update
   ```

{{< /tab >}}

{{< /tabs >}}

### 最新の署名キーをフェッチする {#fetch-latest-signing-key}

最新のリポジトリ署名キーをフェッチするには:

1. キーをダウンロードします:

   ```shell
   curl "https://packages.gitlab.com/gpg.key" -o /tmp/omnibus_gitlab_gpg.key
   ```

1. キーをインポートします:

   {{< tabs >}}

   {{< tab title="Debian/Ubuntu/Raspbian" >}}

   ```shell
   sudo apt-key add /tmp/omnibus_gitlab_gpg.key
   ```

   {{< /tab >}}

   {{< tab title="CentOS/OpenSUSE/SLES" >}}

   ```shell
   sudo rpm --import /tmp/omnibus_gitlab_gpg.key
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. 新しいキーがOSによって適切に認識されるために必要な権限を持っていることを確認してください。これは`644`である必要があります。権限を設定するには、次を実行します:

   ```shell
   chmod 644 <keyfile>
   ```

### 前のキー {#previous-key}

| シリアル番号 | キーID                                               | 有効期限 |
|:--------|:-----------------------------------------------------|:------------|
| 1       | `1A4C 919D B987 D435 9396  38B9 1421 9A96 E15E 78F4` | `2020-04-15` |

## パッケージの署名 {#package-signatures}

このセクションでは、サポートされている場合は手動および自動で、GitLabで生成されたパッケージの署名を検証する方法について説明します。

### 現在のパッケージ署名キーの詳細 {#details-of-current-package-signing-key}

| キーの属性 | 値 |
|---------------|-------|
| 名前          | `GitLab, Inc.` |
| メール         | `support@gitlab.com` |
| フィンガープリント   | `98BF DB87 FCF1 0076 416C 1E0B AD99 7ACC 82DD 593D` |
| 有効期限        | `2026-02-14` |

#### 古いパッケージ署名キー {#older-package-signing-keys}

| シリアル番号 | キーID                                              | 失効日 | 有効期限  | ダウンロード場所 |
|---------|-----------------------------------------------------|-----------------|--------------|-------------------|
| 1       | `9E71 648F 3A35 EA00 CAE4 43E7 1155 1132 6BA7 34DA` | `2025-02-14`    | `2025-07-01` | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-3D645A26AB9FBD22.pub.gpg` |

### RPMベースのディストリビューション {#rpm-based-distributions}

RPM形式には、GPG署名機能の完全な実装が含まれており、この形式に基づくパッケージ管理システムと完全に統合されています。

#### GitLabの公開キーが存在することを確認します。 {#verify-gitlab-public-key-is-present}

RPMベースのLinuxディストリビューションでパッケージを検証するには、GitLab, Inc.の公開キーが`rpm`キーチェーンに存在することを確認します。例: 

```shell
rpm -q gpg-pubkey-82dd593d-67aefdd8 --qf '%{name}-%{version}-%{release} --> %{summary}'
```

このコマンドは、次のいずれかを生成します:

- 公開キーに関する情報。
- キーがインストールされていないというメッセージ。例: `gpg-pubkey-f27eab47-60d4a67e is not installed`。

キーが存在しない場合は、インポートします。例: 

```shell
rpm --import https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
```

#### 署名チェックがアクティブかどうかを確認します {#verify-if-signature-check-is-active}

パッケージ署名チェックが既存のインストールでアクティブかどうかを確認するには、リポジトリファイルのコンテンツを比較します:

1. リポジトリファイルが存在するかどうかを確認します。`file /etc/yum.repos.d/gitlab_gitlab-ce.repo`
1. 署名チェックがアクティブであることを確認します。`grep gpgcheck /etc/yum.repos.d/gitlab_gitlab-ce.repo`このコマンドは、次のように出力する必要があります:

   ```plaintext
   repo_gpgcheck=1
   gpgcheck=1
   ```

   または

   ```plaintext
   repo_gpgcheck=1
   pkg_gpgcheck=1
   ```

ファイルが存在しない場合は、リポジトリがインストールされていません。ファイルが存在するにもかかわらず、`gpgpcheck=0`という出力が表示される場合は、その値を編集して有効にする必要があります。

#### Linuxパッケージ`rpm`ファイルを検証する {#verify-a-linux-package-rpm-file}

公開キーが存在することを確認したら、パッケージを検証します:

```shell
rpm --checksig gitlab-xxx.rpm
```

### Debianベースのディストリビューション {#debian-based-distributions}

Debianパッケージ形式には、パッケージに署名する方法が正式には含まれていません。弊社では`debsig`標準を実装しました。これは十分にドキュメント化されていますが、ほとんどのLinuxディストリビューションではデフォルトで有効になっていません。

次のいずれかの方法で、Linuxパッケージ`deb`ファイルを検証できます:

- 必要な`debsigs`ポリシーとキーリングを設定した後で、`debsig-verify`を使用します。
- 含まれている`_gpgorigin`ファイルをGnuPGで手動で確認します。

#### `debsigs`を設定 {#configure-debsigs}

`debsigs`のポリシーとキーリングの設定は複雑になる可能性があるため、設定用の`gitlab-debsigs.sh`スクリプトを提供しています。このスクリプトを使用するには、公開キーとスクリプトをダウンロードする必要があります。

```shell
curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
curl -JLO "https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/scripts/gitlab-debsigs.sh"
chmod +x gitlab-debsigs.sh
sudo ./gitlab-debsigs.sh gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
```

#### `debsig-verify`で確認する {#verify-with-debsig-verify}

`debsig-verify`の使用方法:

1. [debsigsを設定`debsigs`](#configure-debsigs)。
1. `debsig-verify`パッケージをインストールします。
1. `debsig-verify`を実行してファイルを検証します:

   ```shell
   debsig-verify gitlab-xxx.deb
   ```

#### GnuPGで確認する {#verify-with-gnupg}

`debsig-verify`によってインストールされた依存関係をインストールしたくない場合は、代わりにGnuPGを使用できます:

1. パッケージ署名公開キーをダウンロードしてインポートします:

   ```shell
   curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
   gpg --import gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
   ```

1. 署名ファイル`_gpgorigin`を抽出します:

   ```shell
   ar x gitlab-xxx.deb _gpgorigin
   ```

1. 署名がコンテンツと一致することを確認します:

   ```shell
   ar p gitlab-xxx.deb debian-binary control.tar.xz data.tar.xz | gpg --verify _gpgorigin -
   ```

   このコマンドの出力は、次のようになります:

   ```shell
   gpg: Signature made Tue Aug 01 22:21:11 2017 UTC
   gpg:                using RSA key DBEF89774DDB9EB37D9FC3A03CFCF9BAF27EAB47
   gpg:                issuer "support@gitlab.com"
   gpg: Good signature from "GitLab, Inc. <support@gitlab.com>" [unknown]
   Primary key fingerprint: DBEF 8977 4DDB 9EB3 7D9F  C3A0 3CFC F9BA F27E AB47
   ```

検証が`gpg: BAD signature from "GitLab, Inc. <support@gitlab.com>" [unknown]`で失敗した場合は、以下を確認してください:

- ファイル名が正しい順序で記述されている。
- ファイル名がアーカイブのコンテンツと一致する。

使用するLinuxディストリビューションによっては、アーカイブのコンテンツのサフィックスが異なる場合があります。これは、コマンドをそれに応じて調整する必要があることを意味します。アーカイブのコンテンツを確認するには、`ar t gitlab-xxx.deb`を実行します。

たとえば、Ubuntu Focal（20.04）の場合:

```shell
$ ar t gitlab-ee_17.4.2-ee.0_amd64.deb
debian-binary
control.tar.xz
data.tar.xz
_gpgorigin
```
