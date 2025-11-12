---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NGINXのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[NGINXを設定する](nginx.md)際、以下の問題が発生する可能性があります。

## エラー: `400 Bad Request: too many Host headers` {#error-400-bad-request-too-many-host-headers}

回避策は、`proxy_set_header`設定が`nginx['custom_gitlab_server_config']`設定にないことを確認することです。代わりに、`gitlab.rb`ファイルで[`proxy_set_headers`](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination)設定を使用してください。

## エラー: `Received fatal alert: handshake_failure` {#error-received-fatal-alert-handshake_failure}

というエラーが表示される場合があります:

```plaintext
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
```

この問題は、古いJavaベースのIDEクライアントを使用してGitLabインスタンスとやり取りする場合に発生します。これらのIDEはTLS 1プロトコルを使用できますが、Linuxパッケージのインストールではデフォルトでサポートされていません。

この問題を解決するには、[issue 624](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/624#note_299061)のユーザーと同様に、サーバー上の暗号をアップグレードします。

このサーバーの変更が不可能な場合は、`/etc/gitlab/gitlab.rb`の値を変更して、古い動作にデフォルトで戻すことができます:

```ruby
nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3"
```

## 秘密キーと証明書間の不一致 {#mismatch-between-private-key-and-certificate}

[NGINXログ](https://docs.gitlab.com/administration/logs/#nginx-logs)に、以下が見つかる場合があります:

```plaintext
x509 certificate routines:X509_check_private_key:key values mismatch)
```

この問題は、秘密キーと証明書の間で不一致がある場合に発生します。

これを解決するには、正しい秘密キーを証明書と一致させます:

1. 正しいキーと証明書があることを確認するには、秘密キーと証明書の係数が一致するかどうかを確認します:

   ```shell
   /opt/gitlab/embedded/bin/openssl rsa -in /etc/gitlab/ssl/gitlab.example.com.key -noout -modulus | /opt/gitlab/embedded/bin/openssl sha256

   /opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/ssl/gitlab.example.com.crt -noout -modulus| /opt/gitlab/embedded/bin/openssl sha256
   ```

1. それらが一致することを確認したら、NGINXを再設定してリロードします:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

## `Request Entity Too Large` {#request-entity-too-large}

[NGINXログ](https://docs.gitlab.com/administration/logs/#nginx-logs)に、以下が見つかる場合があります:

```plaintext
Request Entity Too Large
```

この問題は、[最大インポートサイズ](https://docs.gitlab.com/administration/settings/import_and_export_settings/#max-import-size)を大きくした場合に発生します。

これを解決するには、[クライアントの最大本文サイズ](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size)を大きくします。

KubernetesベースのGitLabインストールでは、この設定は[別の名前で指定されています](https://docs.gitlab.com/charts/charts/gitlab/webservice/#proxybodysize)。

`client_max_body_size`の値を大きくするには、次のようにします:

1. `/etc/gitlab/gitlab.rb`を編集して、優先値を設定します:

   ```ruby
   nginx['client_max_body_size'] = '250m'
   ```

1. ファイルを保存して[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
1. 更新された設定で正常にリロードされるように、NGINXを[`HUP`](https://nginx.org/en/docs/control.html)します:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

## セキュリティスキャナーの警告: `NGINX HTTP Server Detection` {#security-scan-warning-nginx-http-server-detection}

この問題は、一部のセキュリティスキャナーが`Server: nginx` HTTPヘッダーを検出した場合に発生します。このアラートを表示するほとんどのスキャナーは、これを`Low`または`Info`の重大度としてマークします。例については、[Nessus](https://www.tenable.com/plugins/nessus/106375)を参照してください。

この警告は無視してください。ヘッダーを削除するメリットは低く、[その存在は使用統計でNGINXプロジェクトをサポートするのに役立ちます](https://trac.nginx.org/nginx/ticket/1644)。

回避策は、`hide_server_tokens`を使用してヘッダーをオフにすることです:

1. `/etc/gitlab/gitlab.rb`を編集して、値を設定します:

   ```ruby
   nginx['hide_server_tokens'] = 'on'
   ```

1. ファイルを保存して[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
1. 更新された設定で正常にリロードされるように、NGINXを[`HUP`](https://nginx.org/en/docs/control.html)します:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

## Web IDEと外部NGINXの使用時にブランチが見つかりません {#branch-not-found-when-using-web-ide-and-external-nginx}

というエラーが表示される場合があります:

```plaintext
Branch 'branch_name' was not found in this project's repository
```

この問題は、NGINX設定ファイルの`proxy_pass`に末尾のスラッシュがある場合に発生します。

これを解決するには、次のようにします:

1. NGINX設定ファイルを編集して、`proxy_pass`に末尾のスラッシュがないようにします:

   ```plaintext
   proxy_pass https://1.2.3.4;
   ```

1. NGINXを再起動します:

   ```shell
   sudo systemctl restart nginx
   ```

## エラー: `worker_connections are not enough` {#error-worker_connections-are-not-enough}

GitLabから`502`エラーが発生し、[NGINXログ](https://docs.gitlab.com/administration/logs/#nginx-logs)に以下が見つかる場合があります:

```plaintext
worker_connections are not enough
```

この問題は、ワーカー接続が低すぎる値に設定されている場合に発生します。

これを解決するには、NGINXワーカー接続をより高い値に設定します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab['nginx']['worker_connections'] = 10240
   ```

   10240接続は、[デフォルト値](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/374b34e2bdc4bccb73665e0dc856ae32d6082d77/files/gitlab-cookbooks/gitlab/attributes/default.rb#L883)です。

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)し、変更を有効にします。
