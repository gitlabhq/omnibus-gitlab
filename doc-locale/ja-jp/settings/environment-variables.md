---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 環境変数の設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

必要に応じて、`/etc/gitlab/gitlab.rb`を使用して、Puma、Sidekiq、Rails、Rakeで使用されるカスタム環境変数を設定できます。これは、インターネットにアクセスするためにプロキシを使用する必要があり、外部でホストされているリポジトリをGitLabに直接クローンする必要がある場合に役立ちます。`/etc/gitlab/gitlab.rb`で、`gitlab_rails['env']`をハッシュ値とともに指定します。例: 

```ruby
gitlab_rails['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
#    "no_proxy" => ".yourdomain.com"  # Wildcard syntax if you need your internal domain to bypass proxy. Do not specify a port.
}
```

プロキシの背後にいる場合は、必要になる可能性がある他のGitLabコンポーネントから環境変数をオーバーライドすることもできます:

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

GitLabは、プロキシURLにユーザー名とパスワードが含まれている場合、HTTP基本認証の使用を試みます。

プロキシの設定では、グロビングに`.`構文を使用します。

プロキシのURL値は、通常は`http://`のみである必要があります。ただし、プロキシ自体に独自のSSL証明書があり、SSLが有効になっている場合は除きます。つまり、`https_proxy`値の場合でも、通常は値を`http://<USERNAME>:<PASSWORD>@example.com:8080`として指定する必要があります。

{{< alert type="note" >}}

HTTP_PROXYまたはHTTPS_PROXY環境変数が設定されていて、ドメインのDNS解決ができない場合、DNSリバインド保護は無効化されます。

{{< /alert >}}

## 変更の適用 {#applying-the-changes}

環境変数に加えられた変更を有効にするには、再構成が必要です。

再構成を実行します:

```shell
sudo gitlab-ctl reconfigure
```

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

### エラー: `Connection reset by peer` (ミラーリングリポジトリの場合) {#error-connection-reset-by-peer-when-mirroring-repositories}

`no_proxy`値にURLのポート番号が含まれている場合、DNS解決が失敗する可能性があります。この問題を解決するには、`no_proxy` URLからポート番号を削除してください。
