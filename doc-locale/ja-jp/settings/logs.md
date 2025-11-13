---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linux packageインストールでのログ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabには[高度なログシステム](https://docs.gitlab.com/administration/logs/)が搭載されており、GitLab内のすべてのサービスとコンポーネントがシステムログを出力します。ここでは、LinuxパッケージのLinuxパッケージインストールでこれらのログを管理するための設定とツールについて説明します。

## サーバー上のコンソールでログを追跡する {#tail-logs-in-a-console-on-the-server}

GitLabログのライブログ更新を表示するために「tail」したい場合は、`gitlab-ctl tail`を使用できます。

```shell
# Tail all logs; press Ctrl-C to exit
sudo gitlab-ctl tail

# Drill down to a sub-directory of /var/log/gitlab
sudo gitlab-ctl tail gitlab-rails

# Drill down to an individual file
sudo gitlab-ctl tail nginx/gitlab_error.log
```

### コンソールでログを追跡し、ファイルに保存する {#tail-logs-in-a-console-and-save-to-a-file}

多くの場合、ログをコンソールに表示し、後でデバッグ/分析するためにファイルに保存すると便利です。このためには、[`tee`](https://en.wikipedia.org/wiki/Tee_(command))ユーティリティを使用します。

```shell
# Use 'tee' to tail all the logs to STDOUT and write to a file at the same time
sudo gitlab-ctl tail | tee --append /tmp/gitlab_tail.log
```

## デフォルトのログディレクトリを設定する {#configure-default-log-directories}

`/etc/gitlab/gitlab.rb`ファイルには、さまざまな種類のログに対応する`log_directory`キーが多数あります。他の場所に配置するすべてのログの値をアンコメントして更新します:

```ruby
# For example:
gitlab_rails['log_directory'] = "/var/log/gitlab/gitlab-rails"
puma['log_directory'] = "/var/log/gitlab/puma"
registry['log_directory'] = "/var/log/gitlab/registry"
...
```

GitalyとMattermostでは、ログディレクトリの設定が異なります:

```ruby
gitaly['configuration'] = {
   logging: {
    dir: "/var/log/gitlab/registry"
   }
}
mattermost['log_file_directory'] = "/var/log/gitlab/registry"
```

`sudo gitlab-ctl reconfigure`を実行して、これらの設定でインスタンスを設定します。

## runitログ {#runit-logs}

Linuxパッケージのインストールにおける[runitで管理](../development/architecture/_index.md#runit)されているサービスは、`svlogd`を使用してログデータを生成します。

- ログは、`current`というファイルに書き込まれます。
- 定期的に、このログは圧縮され、TAI64N形式を使用して名前が変更されます（例: `@400000005f8eaf6f1a80ef5c.s`）。
- 圧縮されたログのファイルシステムの日付印は、GitLabが最後にそのファイルに書き込んだ時刻と一致します。
- `zmore`と`zgrep`を使用すると、圧縮されたログと圧縮されていないログの両方で表示および検索できます。

生成されるファイルの詳細については、[`svlogd`のドキュメント](https://smarden.org/runit/svlogd.8)をお読みください。

次の設定を使用して、`/etc/gitlab/gitlab.rb`の`svlogd`設定を変更できます:

```ruby
# Below are the default values
logging['svlogd_size'] = 200 * 1024 * 1024 # rotate after 200 MB of log data
logging['svlogd_num'] = 30 # keep 30 rotated log files
logging['svlogd_timeout'] = 24 * 60 * 60 # rotate after 24 hours
logging['svlogd_filter'] = "gzip" # compress logs with gzip
logging['svlogd_udp'] = nil # transmit log messages via UDP
logging['svlogd_prefix'] = nil # custom prefix for log messages

# Optionally, you can override the prefix for e.g. Nginx
nginx['svlogd_prefix'] = "nginx"
```

## Logrotate {#logrotate}

GitLabに組み込まれている**logrotate**サービスは、**runit**によってキャプチャされるものを除く、すべてのログを管理します。このサービスは、`gitlab-rails/production.log`や`nginx/gitlab_access.log`などのログデータをローテーションし、圧縮し、最終的に削除します。一般的なlogrotate設定を設定したり、サービスごとのlogrotate設定を設定したり、`/etc/gitlab/gitlab.rb`でlogrotateを完全に無効にしたりできます。

### 一般的なlogrotate設定の設定 {#configuring-common-logrotate-settings}

すべての**logrotate**サービスに共通の設定は、`/etc/gitlab/gitlab.rb`ファイルで設定できます。これらの設定は、各サービスのlogrotate設定ファイルの設定オプションに対応しています。詳細については、logrotate manページ（`man logrotate`）を参照してください。

```ruby
logging['logrotate_frequency'] = "daily" # rotate logs daily
logging['logrotate_maxsize'] = nil # logs will be rotated when they grow bigger than size specified for `maxsize`, even before the specified time interval (daily, weekly, monthly, or yearly)
logging['logrotate_size'] = nil # do not rotate by size by default
logging['logrotate_rotate'] = 30 # keep 30 rotated logs
logging['logrotate_compress'] = "compress" # see 'man logrotate'
logging['logrotate_method'] = "copytruncate" # see 'man logrotate'
logging['logrotate_postrotate'] = nil # no postrotate command by default
logging['logrotate_dateformat'] = nil # use date extensions for rotated files rather than numbers e.g. a value of "-%Y-%m-%d" would give rotated files like production.log-2016-03-09.gz
```

### 個々のサービスlogrotate設定の設定 {#configuring-individual-service-logrotate-settings}

`/etc/gitlab/gitlab.rb`を使用して、個々のサービスごとにlogrotate設定をカスタマイズできます。たとえば、`nginx`サービスのlogrotateの頻度とサイズをカスタマイズするには、次のようにします:

```ruby
nginx['logrotate_frequency'] = nil
nginx['logrotate_size'] = "200M"
```

### logrotateの無効化 {#disabling-logrotate}

`/etc/gitlab/gitlab.rb`の次の設定を使用して、組み込みのlogrotateサービスを無効にすることもできます:

```ruby
logrotate['enable'] = false
```

### Logrotate `notifempty`設定 {#logrotate-notifempty-setting}

logrotateサービスは、`notifempty`の設定を変更できないデフォルトで実行され、次のイシューが解決されます:

- 空のログが不必要にローテーションされ、多くの場合、多数の空のログが保存されます。
- データベースの移行ログなど、長期的なトラブルシューティングに役立つ1回限りのログが30日後に削除されます。

### Logrotateの1回限りの空のログ処理 {#logrotate-one-off-and-empty-log-handling}

ログは、必要に応じて**logrotate**によってローテーションおよび再作成されるようになり、1回限りのログは変更された場合にのみローテーションされます。この設定を適用すると、いくつかの整理を行うことができます:

- `gitlab-rails/gitlab-rails-db-migrate*.log`のような空の1回限りのログは削除できます。
- 以前のバージョンのGitLabによってローテーションおよび圧縮された空のログ。これらの空のログのサイズは通常20バイトです。

### Logrotateを手動で実行する {#run-logrotate-manually}

Logrotateはスケジュールされたジョブですが、オンデマンドでトリガーすることもできます。

`logrotate`を使用してGitLabログのローテーションを手動でトリガーするには、次のコマンドを使用します:

```shell
/opt/gitlab/embedded/sbin/logrotate -fv -s /var/opt/gitlab/logrotate/logrotate.status /var/opt/gitlab/logrotate/logrotate.conf
```

### logrotateがトリガーされる頻度を増やす {#increase-how-often-logrotate-is-triggered}

logrotateスクリプトは50分ごとにトリガーされ、ログのローテーションを試みるまで10分間待機します。

これらの値を変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   logrotate['pre_sleep'] = 600   # sleep 10 minutes before rotating after start-up
   logrotate['post_sleep'] = 3000 # wait 50 minutes after rotating
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## UDPログ転送 {#udp-log-forwarding}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージのインストールでは、svlogdのUDPログ機能を利用できるだけでなく、svlogd以外のログをUDPを使用してsyslog互換のリモートシステムに送信することもできます。syslogプロトコルメッセージをUDP経由で送信するようにLinuxパッケージのインストールを設定するには、次の設定を使用します:

```ruby
logging['udp_log_shipping_host'] = '1.2.3.4' # Your syslog server
# logging['udp_log_shipping_hostname'] = nil # Optional, defaults the system hostname
logging['udp_log_shipping_port'] = 1514 # Optional, defaults to 514 (syslog)
```

{{< alert type="note" >}}

`udp_log_shipping_host`を設定すると、[指定されたホスト名とサービスに対して`svlogd_prefix`が追加](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/logging.rb)されます（[runitで管理](../development/architecture/_index.md#runit)されている各サービス）。

{{< /alert >}}

ログメッセージの例:

```plaintext
Jun 26 06:33:46 ubuntu1204-test production.log: Started GET "/root/my-project/import" for 127.0.0.1 at 2014-06-26 06:33:46 -0700
Jun 26 06:33:46 ubuntu1204-test production.log: Processing by ProjectsController#import as HTML
Jun 26 06:33:46 ubuntu1204-test production.log: Parameters: {"id"=>"root/my-project"}
Jun 26 06:33:46 ubuntu1204-test production.log: Completed 200 OK in 122ms (Views: 71.9ms | ActiveRecord: 12.2ms)
Jun 26 06:33:46 ubuntu1204-test gitlab_access.log: 172.16.228.1 - - [26/Jun/2014:06:33:46 -0700] "GET /root/my-project/import HTTP/1.1" 200 5775 "https://172.16.228.169/root/my-project/import" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36"
2014-06-26_13:33:46.49866 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7nbj0 Sidekiq::Extensions::DelayedMailer JID-bbfb118dd1db20f6c39f5b50 INFO: start
2014-06-26_13:33:46.52608 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7muoc RepositoryImportWorker JID-57ee926c3655fcfa062338ae INFO: start
```

## カスタムNGINXログ形式の使用 {#using-a-custom-nginx-log-format}

デフォルトでは、NGINXアクセスログは、クエリ文字列に埋め込まれた機密情報を隠すように設計された「結合」NGINX形式のバージョンを使用します。カスタムログ形式文字列を使用する場合は、`/etc/gitlab/gitlab.rb`で指定できます。[NGINXドキュメント](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format)で形式の詳細を確認してください。

```ruby
nginx['log_format'] = 'my format string $foo $bar'
mattermost_nginx['log_format'] = 'my format string $foo $bar'
```

## JSONのログ記録 {#json-logging}

構造化ログは、JSON経由でエクスポートして、Elasticsearch、Splunk、または別のログ管理システムで解析できます。JSON形式は、それをサポートするすべてのサービスでデフォルトで有効になっています。

{{< alert type="note" >}}

PostgreSQLは、外部プラグインなしでJSONのログ記録をサポートしていません。ただし、CSV形式でのログ記録はサポートしています:

{{< /alert >}}

```ruby
postgresql['log_destination'] = 'csvlog'
postgresql['logging_collector'] = 'on'
```

これを有効にするには、データベースの再起動が必要です。詳細については、[PostgreSQLのドキュメント](https://www.postgresql.org/docs/12/runtime-config-logging.html)を参照してください。

## テキストログ {#text-logging}

確立されたログ取り込みシステムを使用している顧客は、JSONログ形式の使用を希望しない場合があります。テキスト形式は、`/etc/gitlab/gitlab.rb`で次のように設定し、その後`gitlab-ctl reconfigure`を実行することで設定できます:

```ruby
gitaly['configuration'] = {
   logging: {
    format: ""
   }
}
gitlab_shell['log_format'] = 'text'
gitlab_workhorse['log_format'] = 'text'
registry['log_formatter'] = 'text'
sidekiq['log_format'] = 'text'
gitlab_pages['log_format'] = 'text'
```

{{< alert type="note" >}}

関係するサービスに応じて、ログ形式の属性名にはいくつかのバリエーションがあります（たとえば、Containerレジストリは`log_formatter`を使用し、GitalyとPraefectは両方とも`logging_format`を使用します）。詳細については、[Issue #4280](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4280)を参照してください。

{{< /alert >}}

## rbtrace {#rbtrace}

GitLabには[`rbtrace`](https://github.com/tmm1/rbtrace)が付属しており、Rubyコードのトレース、実行中のすべてのスレッドの表示、メモリダンプの取得などを行うことができます。ただし、これはデフォルトでは有効になっていません。これを有効にするには、`ENABLE_RBTRACE`変数を環境に定義します:

```ruby
gitlab_rails['env'] = {"ENABLE_RBTRACE" => "1"}
```

次に、システムを再設定し、PumaとSidekiqを再起動します。これをLinuxパッケージのインストールで実行するには、rootとして実行します:

```ruby
/opt/gitlab/embedded/bin/ruby /opt/gitlab/embedded/bin/rbtrace
```

## ログレベル/ログレベルの詳細度の設定 {#configuring-log-levelverbosity}

GitLab Rails、Containerレジストリ、GitLab Shell、およびGitalyの最小ログレベル（詳細度）を設定できます:

1. `/etc/gitlab/gitlab.rb`を編集し、ログレベルを設定します:

   ```ruby
   gitlab_rails['env'] = {
     "GITLAB_LOG_LEVEL" => "WARN",
   }
   registry['log_level'] = 'info'
   gitlab_shell['log_level'] = 'INFO'
   gitaly['configuration'] = {
     logging: {
       level: "warn"
     }
   }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< alert type="note" >}}

特定のGitLabログ（`production_json.log`、`graphql_json.log`など）の`log_level`は、[編集できません](https://gitlab.com/groups/gitlab-org/-/epics/6034)。[デフォルトのログレベルのオーバーライド](https://docs.gitlab.com/administration/logs/#override-default-log-level)も参照してください。

{{< /alert >}}

## カスタムロググループの設定 {#setting-a-custom-log-group}

GitLabは、設定された[ディレクトリログ](#configure-default-log-directories)へのカスタムグループの割り当てをサポートしています

`/etc/gitlab/gitlab.rb`ファイルのグローバルな`logging['log_group']`設定は、`gitaly['log_group']`のようなサービスごとの`log_group`設定と同様に設定できます。`log_group`設定を追加するときにインスタンスを設定するには、`sudo gitlab-ctl reconfigure`を実行する必要があります。

グローバルまたはサービスごとの`log_group`を設定すると:

- サービスごとのログディレクトリ（またはグローバル設定を使用している場合はすべてのログディレクトリ）の権限を`0750`に変更して、設定されたグループメンバーがログディレクトリのコンテンツを読み取れるようにします。

- 指定された`log_group`を使用してログを書き込み、ローテーションするように[runit](#runit-logs)を設定します。サービスごとの場合と、runitで管理されるすべてのサービスの場合があります。

### カスタムロググループの制限事項 {#custom-log-group-limitations}

runitによって管理されていないサービス（`/var/log/gitlab/gitlab-rails`の`gitlab-rails`ログなど）の場合、設定された`log_group`設定は継承されません。

グループはホストに既に存在している必要があります。Linuxパッケージのインストールでは、`sudo gitlab-ctl reconfigure`を実行してもグループは作成されません。
