---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: カスタム環境変数を設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

必要に応じて、Puma、Sidekiq、Rails、およびRakeで使用するカスタム環境変数を`/etc/gitlab/gitlab.rb`経由で設定できます。これは、インターネットにアクセスするためにプロキシを使用する必要がある場合や、外部でホストされているリポジトリをGitLabに直接クローンする必要がある場合に役立ちます。`/etc/gitlab/gitlab.rb`で、`gitlab_rails['env']`にハッシュ値を指定します。例: 

```ruby
gitlab_rails['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
#    "no_proxy" => ".yourdomain.com"  # Wildcard syntax if you need your internal domain to bypass proxy. Do not specify a port.
}
```

プロキシの背後にある場合に必要となる可能性のある、他のGitLabコンポーネントからの環境変数をオーバーライドすることもできます:

```ruby
# Needed for proxying Git clones
gitaly['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

gitlab_workhorse['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

gitlab_pages['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

# If you use the docker registry
registry['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}
```

プロキシURLにユーザー名とパスワードが含まれている場合、GitLabはHTTP Basic認証を使用しようとします。

プロキシ設定では、グロビングに`.`構文を使用します。

プロキシに独自のSSL証明書とSSLが有効になっていない限り、プロキシURL値は一般的に`http://`のみである必要があります。これは、`https_proxy`値の場合でも、通常は`http://<USERNAME>:<PASSWORD>@example.com:8080`として値を指定する必要があることを意味します。

> [!note]
> HTTP_PROXYまたはHTTPS_PROXY環境変数が設定され、ドメインDNSを解決することができない場合、DNSリバインド保護は無効になります。

## 変更の適用 {#applying-the-changes}

環境変数に加えられた変更は、有効にするために再構成が必要です。

再構成を実行します:

```shell
sudo gitlab-ctl reconfigure
```

## 注目すべき環境変数 {#noteworthy-environment-variables}

### `TMPDIR` {#tmpdir}

Rubyおよびその他のコンポーネントは、一時ファイルを保存する場所を決定するために`TMPDIR`環境変数を使用します。デフォルトでは、これは`/tmp`です。

次の場合には、カスタム一時ディレクトリを構成する必要があるかもしれません:

- お使いの`/tmp`が限られたスペースの`tmpfs`としてマウントされている場合。
- 大きなファイル（LFSオブジェクトやCIアーティファクトなど）によって`/tmp`がいっぱいになる場合。
- [Geoセカンダリサイト](https://docs.gitlab.com/ee/administration/geo/)が、オブジェクトストレージのレプリケーション中に`/tmp`の空き容量が不足する場合。

カスタム一時ディレクトリを構成するには:

1. ディレクトリを作成し、パーミッションを設定します:

   ```shell
   sudo mkdir -p /var/opt/gitlab/tmp
   sudo chown git:git /var/opt/gitlab/tmp
   sudo chmod 700 /var/opt/gitlab/tmp
   ```

1. RailsとWorkhorseの両方に`TMPDIR`を設定するために`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   gitlab_workhorse['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   ```

   > [!note]
   > 両方の値は同じディレクトリを指す**must**。オブジェクトストレージを有効にしてCI/CDアーティファクトをアップロードする際、Workhorseは`TMPDIR`にメタデータファイルを生成し、そのパスをRailsに渡します。Railsは、ファイルが許可されたディレクトリ（自身の`TMPDIR`を含む）にあることを検証するします。これらの値が異なる場合、アーティファクトのアップロードは`400 Bad Request`で失敗します。

1. GitLabを再構成して再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

1. 設定を検証します:

   ```shell
   sudo gitlab-rails runner "puts ENV['TMPDIR']"
   ```

   出力には、構成されたパスが表示されるはずです。

## トラブルシューティング {#troubleshooting}

### 環境変数が設定されていません {#an-environment-variable-is-not-being-set}

同じ`['env']`に複数のエントリが存在しないことを確認してください。最後のエントリが前のエントリをオーバーライドします。この例では、`NTP_HOST`は設定されません:

```ruby
gitlab_rails['env'] = { 'NTP_HOST' => "<DOMAIN_OF_NTP_SERVICE>" }

gitlab_rails['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}
```

### `TMPDIR`の変更後、CI/CDアーティファクトのアップロードが`400 Bad Request`で失敗する {#cicd-artifact-uploads-fail-with-400-bad-request-after-changing-tmpdir}

もし[カスタム`TMPDIR`](#tmpdir)を構成した後にCI/CDアーティファクトのアップロードが`Content-Type: text/plain`とともに`400 Bad Request`を返す場合、最も可能性が高い原因は、RailsとWorkhorseの`TMPDIR`の値の不一致です。

これを解決するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`で両方の値が一致していることを確認してください:

   ```ruby
   gitlab_rails['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   gitlab_workhorse['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Workhorseログで失敗した相関IDをチェックすることで、不一致を確認できます。構成済みの`TMPDIR`とは異なるディレクトリを指す`local_temp_path`を持つ`metadata.gz`エントリを探してください。

### エラー: リポジトリのミラーリング時に`Connection reset by peer` {#error-connection-reset-by-peer-when-mirroring-repositories}

`no_proxy`値にURLのポート番号が含まれている場合、DNS解決が失敗する可能性があります。この問題を解決するには、`no_proxy` URLからポート番号を削除してください。
