---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: NGINXのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[NGINXを設定する](nginx.md)際に、以下の問題が発生する可能性があります。

## エラー: `400 Bad Request: too many Host headers` {#error-400-bad-request-too-many-host-headers}

回避策としては、`proxy_set_header`設定が`nginx['custom_gitlab_server_config']`設定に含まれていないことを確認してください。代わりに、`gitlab.rb`ファイルで[`proxy_set_headers`](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination)設定を使用してください。

## エラー: `Received fatal alert: handshake_failure` {#error-received-fatal-alert-handshake_failure}

次のエラーが表示されることがあります:

```plaintext
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
```

この問題は、古いJavaベースのIDEクライアントを使用してGitLabインスタンスと対話する際に発生します。それらのIDEはTLS 1プロトコルを使用できますが、Linuxパッケージのインストールではデフォルトでサポートされていません。

このイシューを解決するには、[イシュー624](https://gitlab.com/gitlab-org/gitlab-foss/-/work_items/624#note_299061)のユーザーと同様に、サーバー上の暗号をアップグレードしてください。

このサーバー変更が不可能な場合は、`/etc/gitlab/gitlab.rb`で値を変更することで、古いデフォルトの動作に戻すことができます:

```ruby
nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3"
```

## 秘密キーと証明書の不一致 {#mismatch-between-private-key-and-certificate}

[NGINXログ](https://docs.gitlab.com/administration/logs/#nginx-logs)に、次のエントリが見つかる場合があります:

```plaintext
x509 certificate routines:X509_check_private_key:key values mismatch)
```

この問題は、秘密キーと証明書の間で不一致がある場合に発生します。

これを解決するには、正しい秘密キーを証明書と一致させてください:

1. 正しいキーと証明書があることを確認するには、秘密キーと証明書のモジュラスが一致するかどうかを確認してください:

   ```shell
   /opt/gitlab/embedded/bin/openssl rsa -in /etc/gitlab/ssl/gitlab.example.com.key -noout -modulus | /opt/gitlab/embedded/bin/openssl sha256

   /opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/ssl/gitlab.example.com.crt -noout -modulus| /opt/gitlab/embedded/bin/openssl sha256
   ```

1. 一致することを確認したら、NGINXを再設定してリロードしてください:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

## `Request Entity Too Large` {#request-entity-too-large}

[NGINXログ](https://docs.gitlab.com/administration/logs/#nginx-logs)に、次のエントリが見つかる場合があります:

```plaintext
Request Entity Too Large
```

このエラーは、リクエストが許可されている最大本文サイズを超えた場合に発生します。最近[最大インポートサイズ](https://docs.gitlab.com/administration/settings/import_and_export_settings/#max-import-size)を増やした場合は、NGINXの設定も更新する必要があります。

これを解決するには、[`client_max_body_size`](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size)ディレクティブを設定してください:

1. `/etc/gitlab/gitlab.rb`を編集し、クライアントの最大本文サイズの値を増やします:

   ```ruby
   nginx['client_max_body_size'] = '250m'
   ```

1. ファイルを保存し、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
1. NGINXが更新された設定で正常にリロードされるように、[`HUP`](https://nginx.org/en/docs/control.html)を実行します:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

Kubernetesインストールの場合、`client_max_body_size`の代わりに[`proxyBodySize`](https://docs.gitlab.com/charts/charts/gitlab/webservice/#proxybodysize)を設定します。

## セキュリティスキャン警告: `NGINX HTTP Server Detection` {#security-scan-warning-nginx-http-server-detection}

この問題は、一部のセキュリティスキャナーが`Server: nginx` HTTPヘッダーを検出したときに発生します。このアラートを持つほとんどのスキャナーは、これを`Low`または`Info`重大度としてマークします。例えば、[Nessus](https://www.tenable.com/plugins/nessus/106375)を参照してください。

ヘッダーを削除するメリットは低く、その存在が[使用統計でNGINXプロジェクトをサポートするのに役立つ](https://trac.nginx.org/nginx/ticket/1644)ため、この警告は無視してください。

回避策は、`hide_server_tokens`を使用してヘッダーをオフにすることです:

1. `/etc/gitlab/gitlab.rb`を編集して値を設定します:

   ```ruby
   nginx['hide_server_tokens'] = 'on'
   ```

1. ファイルを保存し、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
1. NGINXが更新された設定で正常にリロードされるように、[`HUP`](https://nginx.org/en/docs/control.html)を実行します:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

## Web IDEと外部NGINXを使用している場合にブランチが見つからない {#branch-not-found-when-using-web-ide-and-external-nginx}

次のエラーが表示されることがあります:

```plaintext
Branch 'branch_name' was not found in this project's repository
```

この問題は、NGINXの設定ファイルの`proxy_pass`に末尾のスラッシュがある場合に発生します。

これを解決するには:

1. NGINXの設定ファイルを編集し、`proxy_pass`に末尾のスラッシュがないようにします:

   ```plaintext
   proxy_pass https://1.2.3.4;
   ```

1. NGINXを再起動します:

   ```shell
   sudo systemctl restart nginx
   ```

## エラー: `worker_connections are not enough` {#error-worker_connections-are-not-enough}

GitLabから`502`エラーが発生し、[NGINXログ](https://docs.gitlab.com/administration/logs/#nginx-logs)に次のエントリが見つかる場合があります:

```plaintext
worker_connections are not enough
```

この問題は、ワーカー接続が低すぎる値に設定されている場合に発生します。

これを解決するには、NGINXのワーカー接続をより高い値に設定します:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab['nginx']['worker_connections'] = 10240
   ```

   10240接続は[デフォルト値](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/374b34e2bdc4bccb73665e0dc856ae32d6082d77/files/gitlab-cookbooks/gitlab/attributes/default.rb#L883)です。

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
