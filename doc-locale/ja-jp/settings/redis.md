---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redisの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## 代替ローカルネットワークRedisインスタンスの使用 {#using-an-alternate-local-redis-instance}

Linuxパッケージのインストールには、Redisがデフォルトで含まれています。GitLabアプリケーションを独自の*ローカル*実行Redisインスタンスに向けるには、次のようにします:

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

1. 変更を有効にするには、GitLabを再設定してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## バンドルされたRedisをTCP経由で到達可能にする {#making-the-bundled-redis-reachable-via-tcp}

Linuxパッケージで管理されているRedisインスタンスをTCP経由で到達可能にする場合は、次の設定を使用します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   redis['port'] = 6379
   redis['bind'] = '127.0.0.1'
   redis['password'] = 'redis-password-goes-here'
   ```

1. ファイルを保存して、変更を有効にするには、GitLabを再設定してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Linuxパッケージを使用してRedis専用サーバーをセットアップする {#setting-up-a-redis-only-server-using-the-linux-package}

GitLabアプリケーションとは別のサーバーにRedisをセットアップする場合は、[LinuxパッケージのインストールからバンドルされたRedis](https://docs.gitlab.com/administration/redis/standalone/)を使用できます。

## 複数のRedisインスタンスでの実行 {#running-with-multiple-redis-instances}

<https://docs.gitlab.com/administration/redis/replication_and_failover/#running-multiple-redis-clusters>を参照してください。

## Redis Sentinel {#redis-sentinel}

<https://docs.gitlab.com/administration/redis/replication_and_failover/>を参照してください。

## フェイルオーバー設定でのRedisの使用 {#using-redis-in-a-failover-setup}

<https://docs.gitlab.com/administration/redis/replication_and_failover/>を参照してください。

## Google Cloud Memorystoreの使用 {#using-google-cloud-memorystore}

Google Cloud Memorystore[は、Redis `CLIENT`コマンドをサポートしていません](https://cloud.google.com/memorystore/docs/redis/product-constraints#blocked_redis_commands)。デフォルトでは、Sidekiqはデバッグ目的で`CLIENT`を設定しようとします。これは、次の設定で無効にできます:

```ruby
gitlab_rails['redis_enable_client'] = false
```

## デフォルトを超えるRedis接続数の増加 {#increasing-the-number-of-redis-connections-beyond-the-default}

デフォルトでは、Redisは10,000クライアント接続のみを受け入れます。10,000を超える接続が必要な場合は、ニーズに合わせて`maxclients`属性を設定します。`maxclients`属性を調整するということは、`fs.file-max`のシステム設定も考慮する必要があることを意味します（例: `sysctl -w fs.file-max=20000`）。

```ruby
redis['maxclients'] = 20000
```

## RedisのTCPスタックの調整 {#tuning-the-tcp-stack-for-redis}

次の設定は、よりパフォーマンスの高いRedisサーバーインスタンスを有効にするためのものです。`tcp_timeout`は、アイドル状態のTCP接続を終了するまでにRedisサーバーが待機する秒単位で設定された値です。`tcp_keepalive`は、通信がない場合にTCP ACKをクライアントに送信するための秒単位で調整可能な設定です。

```ruby
redis['tcp_timeout'] = "60"
redis['tcp_keepalive'] = "300"
```

## ホスト名からのIPアドレスのアナウンス {#announce-ip-from-hostname}

現在、Redisでホスト名を有効にする唯一の方法は、`redis['announce_ip']`を設定することです。ただし、これはRedisインスタンスごとに一意に設定する必要があります。`announce_ip_from_hostname`は、これをオンまたはオフにできるブール値です。ホスト名を動的にフェッチし、`hostname -f`コマンドからホスト名を推測します。

```ruby
redis['announce_ip_from_hostname'] = true
```

## LRUとしてのRedisキャッシュインスタンスの設定 {#setting-the-redis-cache-instance-as-an-lru}

複数のRedisインスタンスを使用すると、[Least Recently Usedキャッシュ](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/)としてRedisを設定できます。これは、Redisキャッシュ、レート制限、リポジトリキャッシュインスタンスに対してのみ行う必要があります。Redisキュー、共有状態インスタンス、およびtracechunksインスタンスは、永続的であることが予想されるデータ（Sidekiqジョブなど）が含まれているため、LRUとして設定しないでください。

メモリ使用量を32 GBに制限するには、次を使用します:

```ruby
redis['maxmemory'] = "32gb"
redis['maxmemory_policy'] = "allkeys-lru"
redis['maxmemory_samples'] = 5
```

## SSL（Secure Sockets Layer）の使用 {#using-secure-sockets-layer-ssl}

SSLの背後で実行するようにRedisを設定できます。

### SSLの背後でのRedisサーバーの実行 {#running-redis-server-behind-ssl}

1. SSLの背後でRedisサーバーを実行するには、`/etc/gitlab/gitlab.rb`で次の設定を使用できます。使用可能な値については、[`redis.conf.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/redis/templates/default/redis.conf.erb)のTLS/SSLセクションを参照してください:

   ```ruby
   redis['tls_port']
   redis['tls_cert_file']
   redis['tls_key_file']
   ```

1. 必要な値を指定したら、変更を有効にするためにGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< alert type="note" >}}

一部の`redis-cli`バイナリは、TLS経由でRedisサーバーに直接接続するためのサポートを備えてビルドされていません。`redis-cli`が`--tls`フラグをサポートしていない場合は、[`stunnel`](https://redis.io/blog/stunnel-secure-redis-ssl/)のようなものを使用して、デバッグ目的で`redis-cli`を使用してRedisサーバーに接続する必要があります。

{{< /alert >}}

### SSL経由でRedisサーバーに接続するようにGitLabクライアントを作成する {#make-gitlab-client-connect-to-redis-server-over-ssl}

SSLのGitLabクライアントのサポートをアクティブにするには:

1. 次の行を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   gitlab_rails['redis_ssl'] = true
   ```

1. 変更を有効にするには、GitLabを再設定してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## SSL証明書 {#ssl-certificates}

RedisにカスタムSSL証明書を使用している場合は、[信頼できる証明書](ssl/_index.md#install-custom-public-certificates)にそれらを追加してください。

## 名前が変更されたコマンド {#renamed-commands}

デフォルトでは、`KEYS`コマンドはセキュリティ対策として無効になっています。

このコマンドまたはその他のコマンドを難読化または無効にする場合は、`redis['rename_commands']`設定を編集して、`/etc/gitlab/gitlab.rb`で次のようにします:

```ruby
redis['rename_commands'] = {
  'KEYS': '',
  'OTHER_COMMAND': 'VALUE'
}
```

- `OTHER_COMMAND`は、変更するコマンドです
- `VALUE`は、次のいずれかである必要があります:
  1. 新しいコマンド名。
  1. `''`。これにより、コマンドが完全に無効になります。

この機能を無効にするには:

1. `/etc/gitlab/gitlab.rb`ファイルの`redis['rename_commands'] = {}`で設定します
1. `sudo gitlab-ctl reconfigure`を実行

## レイジー解放 {#lazy-freeing}

Redis 4では、[レイジー解放](https://antirez.com/news/93)が導入されました。これにより、大きな値を解放する際のパフォーマンスが向上します。

この設定の`false`は、デフォルトでです。これを有効にするには、次を使用します:

```ruby
redis['lazyfree_lazy_eviction'] = true
redis['lazyfree_lazy_expire'] = true
redis['lazyfree_lazy_server_del'] = true
redis['replica_lazy_flush'] = true
```

## スレッド化I/O {#threaded-io}

Redis 6では、スレッド化I/Oが導入されました。これにより、書き込みを複数のコアにスケールできます。

この設定はデフォルトで無効になっています。これを有効にするには、次を使用します:

```ruby
redis['io_threads'] = 4
redis['io_threads_do_reads'] = true
```

### クライアントタイムアウト {#client-timeouts}

デフォルトでは、[Ruby用のRubyクライアント](https://github.com/redis-rb/redis-client?tab=readme-ov-file#configuration)は、接続、読み取り、および書き込みタイムアウトに1秒のデフォルトを使用します。これらの値を調整して、ローカルネットワークのレイテンシーを考慮する必要がある場合があります。たとえば、`Connection timed out - user specified timeout`エラーが表示される場合は、`connect_timeout`を上げる必要がある場合があります:

```ruby
gitlab_rails['redis_connect_timeout'] = 3
gitlab_rails['redis_read_timeout'] = 1
gitlab_rails['redis_write_timeout'] = 1
```

## プレーンテキストストレージなしで機密性の高い設定をRedisクライアントに提供する {#provide-sensitive-configuration-to-redis-clients-without-plain-text-storage}

詳細については、[設定ドキュメント](configuration.md#provide-redis-password-to-redis-server-and-client-components)の例を参照してください。

## トラブルシューティング {#troubleshooting}

### `x509: certificate signed by unknown authority` {#x509-certificate-signed-by-unknown-authority}

このエラーメッセージは、SSL証明書がサーバーの信頼できる証明書のリストに適切に追加されていないことを示唆しています。これがイシューであるかどうかを確認するには:

1. `/var/log/gitlab/gitlab-workhorse/current`でWorkhorse GitLabログを確認します。

1. 次のようなメッセージが表示された場合:

   ```plaintext
   2018-11-14_05:52:16.71123 time="2018-11-14T05:52:16Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_05:52:16.74397 time="2018-11-14T05:52:16Z" level=error msg="unknown error" error="keywatcher: x509: certificate signed by unknown authority"
   ```

   最初の行は、Redisサーバーのアドレスを持つスキームとして`rediss`を表示する必要があります。2行目は、このサーバーで証明書が適切に信頼されていないことを示しています。[前のセクション](#ssl-certificates)を参照してください。

1. [これらのトラブルシューティング手順](ssl/ssl_troubleshooting.md#custom-certificates-missing-or-skipped)でSSL証明書が機能していることを確認してください。

### 認証が必要なNOAUTH {#noauth-authentication-required}

Redisサーバーは、コマンドが受け入れられる前に、`AUTH`メッセージを介して送信されるパスワードを必要とする場合があります。`NOAUTH Authentication required`エラーメッセージは、クライアントがパスワードを送信していないことを示唆しています。GitLabログは、このエラーのトラブルシューティングに役立つ場合があります:

1. `/var/log/gitlab/gitlab-workhorse/current`でWorkhorse GitLabログを確認します。

1. 次のようなメッセージが表示された場合:

   ```plaintext
   2018-11-14_06:18:43.81636 time="2018-11-14T06:18:43Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_06:18:43.86929 time="2018-11-14T06:18:43Z" level=error msg="unknown error" error="keywatcher: pubsub receive: NOAUTH Authentication required."
   ```

1. `/etc/gitlab/gitlab.rb`で指定されたRedisクライアントパスワードが正しいことを確認してください:

   ```ruby
   gitlab_rails['redis_password'] = 'your-password-here'
   ```

1. Linuxパッケージが提供するRedisサーバーを使用している場合は、サーバーに同じパスワードがあることを確認してください:

   ```ruby
   redis['password'] = 'your-password-here'
   ```

### Redis接続リセット (ECONNRESET) {#redis-connection-reset-econnreset}

GitLab Railsログ（`/var/log/gitlab-rails/production.log`）に`Redis::ConnectionError: Connection lost (ECONNRESET)`が表示される場合、これは、サーバーがSSLを予期しているが、クライアントがそれを使用するように設定されていないことを示している可能性があります。

1. サーバーが実際にSSLを介してポートをリッスンしていることを確認してください。例: 

   ```shell
   /opt/gitlab/embedded/bin/openssl s_client -connect redis-server:6379
   ```

1. `/var/opt/gitlab/gitlab-rails/etc/resque.yml`を確認してください。次のようなものが表示されるはずです:

   ```yaml
   production:
     url: rediss://:mypassword@redis-server:6379/
   ```

1. `redis://`が`rediss://`の代わりに存在する場合、`redis_ssl`パラメータが適切に設定されていないか、再設定手順が実行されていない可能性があります。

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

- 必要な場合にRedisへの認証のパスワード:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379 -a <password>
  ```
