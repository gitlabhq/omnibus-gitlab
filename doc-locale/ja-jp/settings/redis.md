---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redisの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## 代替のローカルRedisインスタンスを使用する {#using-an-alternate-local-redis-instance}

Linuxパッケージインストールには、デフォルトでRedisが含まれています。GitLabアプリケーションを独自の*ローカルで*実行されているRedisインスタンスに指定するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Disable the bundled Redis
   redis['enable'] = false

   # Redis via TCP
   gitlab_rails['redis_host'] = '127.0.0.1'
   gitlab_rails['redis_port'] = 6379

   # OR Redis via Unix domain sockets
   gitlab_rails['redis_socket'] = '/tmp/redis.sock' # defaults to /var/opt/gitlab/redis/redis.socket

   # Password to Authenticate to alternate local Redis if required
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. 変更を反映するためにGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## バンドルされたRedisをTCP経由で到達可能にする {#making-the-bundled-redis-reachable-via-tcp}

次の設定を使用して、Linuxパッケージで管理されているRedisインスタンスをTCP経由で到達可能にする場合は、これを使用します:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   redis['port'] = 6379
   redis['bind'] = '127.0.0.1'
   redis['password'] = 'redis-password-goes-here'
   ```

1. ファイルを保存し、変更を有効にするためにGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Linuxパッケージを使用してRedis専用サーバーを設定する {#setting-up-a-redis-only-server-using-the-linux-package}

GitLabアプリケーションとは別のサーバーにRedisを設定したい場合は、[バンドルされたRedisをLinuxパッケージインストールから](https://docs.gitlab.com/administration/redis/standalone/)使用できます。

## 複数のRedisインスタンスで実行する {#running-with-multiple-redis-instances}

<https://docs.gitlab.com/administration/redis/replication_and_failover/#running-multiple-redis-clusters>を参照してください。

## Redis Sentinel {#redis-sentinel}

<https://docs.gitlab.com/administration/redis/replication_and_failover/>を参照してください。

## フェイルオーバー設定でRedisを使用する {#using-redis-in-a-failover-setup}

<https://docs.gitlab.com/administration/redis/replication_and_failover/>を参照してください。

## Google Cloud Memorystoreを使用する {#using-google-cloud-memorystore}

Google Cloud Memorystore [はRedis `CLIENT`コマンドをサポートしていません](https://docs.cloud.google.com/memorystore/docs/redis/product-constraints#blocked_redis_commands)。デフォルトでは、Sidekiqは`CLIENT`をデバッグ目的で設定しようとします。これは、次の設定で無効にできます:

```ruby
gitlab_rails['redis_enable_client'] = false
```

## Redis接続数をデフォルトより増やす {#increasing-the-number-of-redis-connections-beyond-the-default}

デフォルトでは、Redisは10,000のクライアント接続のみを受け入れます。10,000を超える接続が必要な場合は、`maxclients`属性をニーズに合わせて設定してください。`maxclients`属性を調整すると、`fs.file-max` (`sysctl -w fs.file-max=20000`など) のシステム設定も考慮する必要があることに注意してください。

```ruby
redis['maxclients'] = 20000
```

## RedisのTCPスタックをチューニングする {#tuning-the-tcp-stack-for-redis}

次の設定は、より高性能なRedisサーバーインスタンスを有効にするためのものです。`tcp_timeout`は、Redisサーバーがアイドル状態のTCP接続を終了するまでに待機する秒単位の値です。`tcp_keepalive`は、通信がない場合にクライアントへのTCP ACKの秒単位で調整可能な設定です。

```ruby
redis['tcp_timeout'] = "60"
redis['tcp_keepalive'] = "300"
```

## ホスト名からIPをアナウンスする {#announce-ip-from-hostname}

現在、Redisでホスト名を有効にする唯一の方法は、`redis['announce_ip']`を設定することです。ただし、これはRedisインスタンスごとに一意に設定する必要があります。`announce_ip_from_hostname`は、これをオンまたはオフにするためのブール値です。ホスト名を動的にフェッチし、`hostname -f`コマンドからホスト名を推測します。

```ruby
redis['announce_ip_from_hostname'] = true
```

## RedisキャッシュインスタンスをLRUとして設定する {#setting-the-redis-cache-instance-as-an-lru}

複数のRedisインスタンスを使用すると、Redisを[Least Recently Usedキャッシュ](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/)として設定できます。これはRedisキャッシュ、レート制限、およびリポジトリキャッシュインスタンスにのみ行うべきです。Redisキュー、共有状態インスタンス、およびtracechunksインスタンスは、永続的であると予想されるデータ（Sidekiqジョブなど）を含むため、LRUとして設定すべきではありません。

メモリ使用量を32 GBに制限するには、次を使用できます:

```ruby
redis['maxmemory'] = "32gb"
redis['maxmemory_policy'] = "allkeys-lru"
redis['maxmemory_samples'] = 5
```

## Secure Sockets Layer (SSL) を使用する {#using-secure-sockets-layer-ssl}

RedisをSSLの背後で実行するように設定できます。

### RedisサーバーをSSLの背後で実行する {#running-redis-server-behind-ssl}

1. RedisサーバーをSSLの背後で実行するには、`/etc/gitlab/gitlab.rb`に次の設定を使用できます。可能な値については、[`redis.conf.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/redis/templates/default/redis.conf.erb)のTLS/SSLセクションを参照してください:

   ```ruby
   redis['tls_port']
   redis['tls_cert_file']
   redis['tls_key_file']
   ```

1. 必要な値を指定したら、変更を有効にするためにGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 一部の`redis-cli`バイナリは、TLS経由でRedisサーバーに直接接続するためのサポートが組み込まれていません。`redis-cli`が`--tls`フラグをサポートしていない場合は、デバッグ目的で`redis-cli`を使用してRedisサーバーに接続するために、[`stunnel`](https://redis.io/blog/stunnel-secure-redis-ssl/)のようなものを使用する必要があります。

### GitLabクライアントをSSL経由でRedisサーバーに接続させる {#make-gitlab-client-connect-to-redis-server-over-ssl}

SSLに対するGitLabクライアントサポートをアクティブにするには:

1. `/etc/gitlab/gitlab.rb`に次の行を追加します:

   ```ruby
   gitlab_rails['redis_ssl'] = true
   ```

1. 変更を反映するためにGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## SSL証明書 {#ssl-certificates}

RedisにカスタムSSL証明書を使用している場合は、それらを[信頼された証明書](ssl/_index.md#install-custom-public-certificates)に追加してください。

## コマンドの名前変更 {#renamed-commands}

デフォルトでは、`KEYS`コマンドはセキュリティ対策として無効になっています。

このコマンドやその他のコマンドを難読化または無効にしたい場合は、`/etc/gitlab/gitlab.rb`の`redis['rename_commands']`設定を次のように編集してください:

```ruby
redis['rename_commands'] = {
  'KEYS': '',
  'OTHER_COMMAND': 'VALUE'
}
```

- `OTHER_COMMAND`は変更したいコマンドです
- `VALUE`は次のいずれかである必要があります:
  1. 新しいコマンド名。
  1. コマンドを完全に無効にする`''`。

この機能を無効にするには:

1. `/etc/gitlab/gitlab.rb`ファイルで`redis['rename_commands'] = {}`を設定します
1. `sudo gitlab-ctl reconfigure` を実行

## レイジーフリー {#lazy-freeing}

Redis 4では[レイジーフリー](https://antirez.com/news/93)が導入されました。これにより、大きな値を解放する際のパフォーマンスが向上します。

この設定は`false`にデフォルトします。これを有効にするには、次を使用できます:

```ruby
redis['lazyfree_lazy_eviction'] = true
redis['lazyfree_lazy_expire'] = true
redis['lazyfree_lazy_server_del'] = true
redis['replica_lazy_flush'] = true
```

## スレッドI/O {#threaded-io}

Redis 6ではスレッドI/Oが導入されました。これにより、複数のコアにわたって書き込みをスケールすることができます。

この設定はデフォルトで無効になっています。これを有効にするには、次を使用できます:

```ruby
redis['io_threads'] = 4
redis['io_threads_do_reads'] = true
```

### クライアントタイムアウト {#client-timeouts}

デフォルトでは、[Redis用のRubyクライアント](https://github.com/redis-rb/redis-client?tab=readme-ov-file#configuration)は、接続、読み取り、および書き込みのタイムアウトに1秒のデフォルトを使用します。ローカルネットワークのレイテンシーを考慮して、これらの値を調整する必要がある場合があります。たとえば、`Connection timed out - user specified timeout`エラーが表示される場合は、`connect_timeout`を上げる必要がある場合があります:

```ruby
gitlab_rails['redis_connect_timeout'] = 3
gitlab_rails['redis_read_timeout'] = 1
gitlab_rails['redis_write_timeout'] = 1
```

## プレーンテキストストレージなしで機密性の高い設定をRedisクライアントに提供する {#provide-sensitive-configuration-to-redis-clients-without-plain-text-storage}

詳細については、[設定ドキュメント](configuration.md#provide-redis-password-to-redis-server-and-client-components)に記載された例を参照してください。

## Redisの代わりにValkeyを使用する {#using-valkey-instead-of-redis}

{{< history >}}

- GitLab 18.9で[ベータ版](https://docs.gitlab.com/policy/development_stages_support/#beta)として[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113)されました。
- GitLab 19.0で[一般提供](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9383)になりました。

{{< /history >}}

[Valkey](https://valkey.io/)は、Redisのドロップイン代替として使用できるRedis互換のキーと値のストアです。Valkeyは、Redis OSS 7.2およびすべての以前のオープンソースRedisバージョンと互換性があります。

Valkeyを使用する場合:

- サービス名は`redis`のままです。サービスを管理するには`gitlab-ctl restart redis`を使用し、`gitlab-ctl restart valkey`は使用しません。
- ログファイルは`/var/log/gitlab/redis/`に書き込まれ、別の`valkey`ディレクトリには書き込まれません。
- データディレクトリは`/var/opt/gitlab/redis/`のままです。
- 設定ファイルは`redis.conf`のままです。
- `gitlab-ctl`ツールは、Redisとのやり取りに引き続き`redis-cli`を使用します。
- `valkey-cli`をトラブルシューティングに使用する場合は、`redis-cli`と同じソケット、ホスト、およびポートを使用します:

  ```shell
  sudo /opt/gitlab/embedded/bin/valkey-cli -s /var/opt/gitlab/redis/redis.socket
  ```

RedisからValkeyへの移行の詳細については、[Valkey移行ドキュメント](https://valkey.io/topics/migration/)を参照してください。

### Valkeyにスイッチする {#switch-to-valkey}

Redisの代わりにValkeyを使用するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   redis['backend'] = 'valkey'
   ```

1. 変更を反映するためにGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`redis['backend']`が`valkey`に設定されている場合:

- Redisサービスは`redis-server`の代わりに`valkey-server`を使用します。
- Sentinelサービスは`redis-sentinel`の代わりに`valkey-sentinel`を使用します。
- その他のすべてのRedis設定 (ポート、パスワード、パスなど) は同じままです。

#### サービス管理 {#service-management}

後方互換性とシームレスな移行を確保するために、バックエンドとしてRedisまたはValkeyのどちらを使用するかに関わらず、サービス構造は一貫性を保ちます:

- サービス名は`redis`です。サービスを管理するには`gitlab-ctl restart redis`を使用します。
- ログファイルは`/var/log/gitlab/redis/`に書き込まれます。
- データディレクトリは`/var/opt/gitlab/redis/`です。
- 設定ファイルは`redis.conf`です。
- `gitlab-ctl`コマンドは、構成されたバックエンドに基づいて、適切なCLIツール（`redis-cli`または`valkey-cli`）を使用します。
- トラブルシューティングには、アクティブなバックエンドを自動的に検出するラッパースクリプトを使用してください:

  ```shell
  sudo gitlab-redis-cli
  ```

RedisからValkeyへの移行の詳細については、[Valkey移行ドキュメント](https://valkey.io/topics/migration/)を参照してください。

## トラブルシューティング {#troubleshooting}

### `x509: certificate signed by unknown authority` {#x509-certificate-signed-by-unknown-authority}

このエラーメッセージは、SSL証明書がサーバーの信頼された証明書のリストに適切に追加されていないことを示唆しています。これがイシューであるかどうかを確認するには:

1. `/var/log/gitlab/gitlab-workhorse/current`のWorkhorseログファイルを確認してください。
1. 次のようなメッセージが表示される場合:

   ```plaintext
   2018-11-14_05:52:16.71123 time="2018-11-14T05:52:16Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_05:52:16.74397 time="2018-11-14T05:52:16Z" level=error msg="unknown error" error="keywatcher: x509: certificate signed by unknown authority"
   ```

   最初の行には、Redisサーバーのアドレスとともにスキームとして`rediss`が表示されるはずです。2行目は、このサーバーで証明書が適切に信頼されていないことを示しています。[前のセクション](#ssl-certificates)を参照してください。

1. SSL証明書が[これらのトラブルシューティングステップ](ssl/ssl_troubleshooting.md#custom-certificates-missing-or-skipped)によって機能していることを確認してください。

### NOAUTH認証が必要です {#noauth-authentication-required}

Redisサーバーは、コマンドが受け入れられる前に`AUTH`メッセージを介して送信されたパスワードを必要とする場合があります。`NOAUTH Authentication required`エラーメッセージは、クライアントがパスワードを送信していないことを示唆しています。GitLabログファイルがこのエラーのトラブルシューティングを行うのに役立つ場合があります:

1. `/var/log/gitlab/gitlab-workhorse/current`のWorkhorseログファイルを確認してください。
1. 次のようなメッセージが表示される場合:

   ```plaintext
   2018-11-14_06:18:43.81636 time="2018-11-14T06:18:43Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_06:18:43.86929 time="2018-11-14T06:18:43Z" level=error msg="unknown error" error="keywatcher: pubsub receive: NOAUTH Authentication required."
   ```

1. `/etc/gitlab/gitlab.rb`で指定されているRedisクライアントのパスワードが正しいことを確認してください:

   ```ruby
   gitlab_rails['redis_password'] = 'your-password-here'
   ```

1. Linuxパッケージが提供するRedisサーバーを使用している場合は、サーバーが同じパスワードを持っていることを確認してください:

   ```ruby
   redis['password'] = 'your-password-here'
   ```

### Redis接続リセット (ECONNRESET) {#redis-connection-reset-econnreset}

GitLab Railsログファイル (`/var/log/gitlab-rails/production.log`) で`Redis::ConnectionError: Connection lost (ECONNRESET)`が表示される場合、これはサーバーがSSLを期待しているにもかかわらず、クライアントがそれを使用するように設定されていないことを示している可能性があります。

1. サーバーが実際にSSL経由でポートをリッスンしていることを確認してください。例: 

   ```shell
   /opt/gitlab/embedded/bin/openssl s_client -connect redis-server:6379
   ```

1. `/var/opt/gitlab/gitlab-rails/etc/resque.yml`を確認してください。次のようなものが表示されるはずです:

   ```yaml
   production:
     url: rediss://:mypassword@redis-server:6379/
   ```

1. `rediss://`の代わりに`redis://`が存在する場合、`redis_ssl`パラメータが適切に設定されていないか、再設定ステップが実行されていない可能性があります。

### CLI経由でRedisに接続する {#connecting-to-redis-via-the-cli}

トラブルシューティングのためにRedisに接続する場合、次を使用できます:

- Unixドメインソケット経由のRedis:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
  ```

- TCP経由のRedis:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379
  ```

- 必要に応じてRedisに認証するためのパスワード:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379 -a <password>
  ```
