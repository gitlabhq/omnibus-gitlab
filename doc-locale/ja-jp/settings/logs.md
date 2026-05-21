---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージインストールでのログ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabには、すべてのサービスとコンポーネントがシステムログを出力する[高度なログシステム](https://docs.gitlab.com/administration/logs/)が含まれています。Linuxパッケージインストールでこれらのログを管理するための設定とツールを以下に示します。

## サーバーのコンソールでログをテールする {#tail-logs-in-a-console-on-the-server}

'tail'、つまりGitLabのログのライブ更新を表示したい場合は、`gitlab-ctl tail`を使用できます。

```shell
# Tail all logs; press Ctrl-C to exit
sudo gitlab-ctl tail

# Drill down to a sub-directory of /var/log/gitlab
sudo gitlab-ctl tail gitlab-rails

# Drill down to an individual file
sudo gitlab-ctl tail nginx/gitlab_error.log
```

### コンソールでログをテールしてファイルに保存する {#tail-logs-in-a-console-and-save-to-a-file}

多くの場合、ログをコンソールに表示するだけでなく、後のデバッグ/分析のためにファイルに保存すると便利です。これを行うには、[`tee`](https://en.wikipedia.org/wiki/Tee_(command))ユーティリティを使用できます。

```shell
# Use 'tee' to tail all the logs to STDOUT and write to a file at the same time
sudo gitlab-ctl tail | tee --append /tmp/gitlab_tail.log
```

## デフォルトのログディレクトリを設定する {#configure-default-log-directories}

`/etc/gitlab/gitlab.rb`ファイルには、様々な種類のログに対する多数の`log_directory`キーがあります。他の場所に配置したいすべてのログの値をアンコメントして更新します:

```ruby
# For example:
gitlab_rails['log_directory'] = "/var/log/gitlab/gitlab-rails"
puma['log_directory'] = "/var/log/gitlab/puma"
registry['log_directory'] = "/var/log/gitlab/registry"
...
```

GitalyとMattermostは、異なるログディレクトリ設定を持っています:

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

Linuxパッケージインストール内の[runit管理](../development/architecture/_index.md#runit)サービスは、`svlogd`を使用してログデータを生成します。

- ログは`current`という名前のファイルに書き込まれます。
- 定期的に、このログはTAI64N形式を使用して圧縮され、例えば`@400000005f8eaf6f1a80ef5c.s`のように名前が変更されます。
- 圧縮されたログのファイルシステムのデータスタンプは、GitLabが最後にそのファイルに書き込んだ時刻と一致します。
- `zmore`と`zgrep`を使用すると、圧縮されたログと未圧縮のログの両方を表示および検索できます。

生成されるファイルの詳細については、[`svlogd`ドキュメント](https://smarden.org/runit/svlogd.8)をお読みください。

`svlogd`の設定は、`/etc/gitlab/gitlab.rb`で以下の設定を使用して変更できます:

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

GitLabに組み込まれている**logrotate**サービスは、**runit**によって取得されたログを除くすべてのログを管理します。このサービスは、`gitlab-rails/production.log`や`nginx/gitlab_access.log`などのログデータをローテーション、圧縮し、最終的に削除します。一般的なlogrotateの設定、サービスごとのlogrotateの設定、および`/etc/gitlab/gitlab.rb`を使用してlogrotateを完全に無効にすることができます。

### 一般的なlogrotateの設定 {#configuring-common-logrotate-settings}

すべての**logrotate**サービスに共通する設定は、`/etc/gitlab/gitlab.rb`ファイルで設定できます。これらの設定は、各サービスのlogrotate設定ファイル内の設定オプションに対応しています。詳細については、logrotateのmanページ(`man logrotate`)を参照してください。

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

### 個々のサービスlogrotateの設定 {#configuring-individual-service-logrotate-settings}

`/etc/gitlab/gitlab.rb`を使用して、個々のサービスごとにlogrotateの設定をカスタマイズできます。例えば、`nginx`サービスのlogrotateの頻度とサイズをカスタマイズするには、次を使用します:

```ruby
nginx['logrotate_frequency'] = nil
nginx['logrotate_size'] = "200M"
```

### logrotateの無効化 {#disabling-logrotate}

`/etc/gitlab/gitlab.rb`で以下の設定を使用して、組み込みのlogrotateサービスを無効にすることもできます:

```ruby
logrotate['enable'] = false
```

### Logrotateの`notifempty`設定 {#logrotate-notifempty-setting}

logrotateサービスは、`notifempty`という設定不可能なデフォルトで実行され、以下の問題を解決します:

- 空のログが不必要にローテーションされ、多くの空のログが保存されること。
- データベース移行ログなど、長期的なトラブルシューティングに役立つ一度限りのログが30日後に削除されること。

### Logrotateの一度限りのログと空のログの処理 {#logrotate-one-off-and-empty-log-handling}

ログは必要に応じて**logrotate**によってローテーションされ、再作成されるようになりました。一度限りのログは変更があった場合にのみローテーションされます。この設定を適用すると、いくつかの整理を行うことができます:

- `gitlab-rails/gitlab-rails-db-migrate*.log`などの空の一度限りのログは削除できます。
- 古いバージョンのGitLabによってローテーションおよび圧縮された空のログ。これらの空のログは通常20バイトのサイズです。

### logrotateを手動で実行する {#run-logrotate-manually}

Logrotateはスケジュールされたジョブですが、オンデマンドでトリガーすることもできます。

GitLabのログローテーションを`logrotate`で手動でトリガーするには、次のコマンドを使用します:

```shell
/opt/gitlab/embedded/sbin/logrotate -fv -s /var/opt/gitlab/logrotate/logrotate.status /var/opt/gitlab/logrotate/logrotate.conf
```

### logrotateがトリガーされる頻度を増やす {#increase-how-often-logrotate-is-triggered}

logrotateスクリプトは50分ごとにトリガーされ、ログのローテーションを試行する前に10分間待機します。

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

Linuxパッケージインストールは、svlogdのUDPロギング機能を利用できるだけでなく、非svlogdログをUDPを使用してsyslog互換のリモートシステムに送信することもできます。LinuxパッケージインストールがUDP経由でsyslogプロトコルメッセージを送信するように設定するには、以下の設定を使用します:

```ruby
logging['udp_log_shipping_host'] = '1.2.3.4' # Your syslog server
# logging['udp_log_shipping_hostname'] = nil # Optional, defaults the system hostname
logging['udp_log_shipping_port'] = 1514 # Optional, defaults to 514 (syslog)
```

> [!note]
> `udp_log_shipping_host`の設定により、指定されたホスト名とサービスに対して、各[runit管理](../development/architecture/_index.md#runit)サービスの[`svlogd_prefix`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/logging.rb)が追加されます。

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

## カスタムNGINXログフォーマットの使用 {#using-a-custom-nginx-log-format}

デフォルトでは、NGINXアクセスログは「結合」NGINXフォーマットのバージョンを使用します。これは、クエリ文字列に埋め込まれた可能性のある機密情報を隠すように設計されています。カスタムログフォーマット文字列を使用したい場合は、`/etc/gitlab/gitlab.rb`で指定できます。[NGINXドキュメント](https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format)でフォーマットの詳細を参照してください。

```ruby
nginx['log_format'] = 'my format string $foo $bar'
mattermost_nginx['log_format'] = 'my format string $foo $bar'
```

## JSONのログ記録 {#json-logging}

構造化されたログは、JSON経由でElasticsearch、Splunk、または別のログ管理システムによって解析するためにエクスポートできます。JSONフォーマットは、それをサポートするすべてのサービスに対してデフォルトで有効になっています。

> [!note]
> PostgreSQLは、外部プラグインなしではJSONのログ記録をサポートしていません。しかし、CSV形式でのロギングはサポートしています:

```ruby
postgresql['log_destination'] = 'csvlog'
postgresql['logging_collector'] = 'on'
```

これを有効にするには、データベースの再起動が必要です。詳細については、[PostgreSQLドキュメント](https://www.postgresql.org/docs/12/runtime-config-logging.html)を参照してください。

## テキストロギング {#text-logging}

確立されたログ取り込みシステムを持つ顧客は、JSONログフォーマットの使用を希望しない場合があります。テキストフォーマットは、`/etc/gitlab/gitlab.rb`で以下を設定し、その後`gitlab-ctl reconfigure`を実行することで設定できます:

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

> [!note]
> ログフォーマットの属性名には、関与するサービスによっていくつかのバリエーションがあります (例えば、コンテナレジストリは`log_formatter`を使用し、GitalyとPraefectは両方とも`logging_format`を使用します)。詳細については、[Issue #4280](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4280)を参照してください。

## rbtrace {#rbtrace}

GitLabには[`rbtrace`](https://github.com/tmm1/rbtrace)が同梱されており、Ruby codeをトレースしたり、実行中のすべてのスレッドを表示したり、メモリダンプを取得したりできます。しかし、これはデフォルトでは有効になっていません。これを有効にするには、環境に`ENABLE_RBTRACE`変数を定義します:

```ruby
gitlab_rails['env'] = {"ENABLE_RBTRACE" => "1"}
```

その後、システムを再設定し、PumaとSidekiqを再起動します。これをLinuxパッケージインストールで実行するには、rootとして実行します:

```ruby
/opt/gitlab/embedded/bin/ruby /opt/gitlab/embedded/bin/rbtrace
```

## ログレベル/詳細度を設定する {#configuring-log-levelverbosity}

GitLab Rails、コンテナレジストリ、GitLab Shell、およびGitalyの最小ログレベル（詳細度）を設定できます:

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

> [!note]
> 特定のGitLabログ（例: `production_json.log`、`graphql_json.log`など）の`log_level`は[編集できません](https://gitlab.com/groups/gitlab-org/-/epics/6034)。また、[デフォルトのログレベルをオーバーライド](https://docs.gitlab.com/administration/logs/#override-default-log-level)も参照してください。

## カスタムロググループの設定 {#setting-a-custom-log-group}

GitLabは、設定された[ログディレクトリ](#configure-default-log-directories)にカスタムグループを割り当てることをサポートしています。

`/etc/gitlab/gitlab.rb`ファイル内のグローバルな`logging['log_group']`設定は、`gitaly['log_group']`のようなサービスごとの`log_group`設定と同様に設定できます。`log_group`設定を追加する際には、インスタンスを設定するために`sudo gitlab-ctl reconfigure`を実行する必要があります。

グローバルまたはサービスごとの`log_group`を設定すると、次のようになります:

- サービスごとのログディレクトリ（またはグローバル設定を使用している場合はすべてのログディレクトリ）のパーミッションを`0750`に変更し、設定されたグループメンバーがログディレクトリの内容を読み取りできるようにします。
- 指定された`log_group`を使用して、[runit](#runit-logs)がログを書き込み、ローテーションするように設定します: サービスごと、またはすべてのrunit管理サービスに対して。

### カスタムロググループの制限 {#custom-log-group-limitations}

runitによって管理されないサービス（例: `/var/log/gitlab/gitlab-rails`内の`gitlab-rails`ログ）のログは、設定された`log_group`設定を継承しません。

グループはホスト上にすでに存在している必要があります。Linuxパッケージインストールは、`sudo gitlab-ctl reconfigure`の実行時にグループを作成しません。
