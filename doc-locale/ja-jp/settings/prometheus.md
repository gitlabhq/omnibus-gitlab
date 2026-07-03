---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Prometheusの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## リモート読み取り/書き込み {#remote-readwrite}

Prometheusは、リモートサービスへの読み取りと書き込みをサポートしています。

リモートの読み取りまたは書き込みサービスを設定するには、`gitlab.rb`に以下を含めます。

```ruby
prometheus['remote_write'] = [
  {
    url: 'https://some-remote-write-service.example.com',
    basic_auth: {
      password: 'remote write secret password'
    }
  }
]
prometheus['remote_read'] = [
  {
    url: 'https://some-remote-write-service.example.com'
  }
]
```

設定オプションの詳細については、Prometheusの設定に関する情報を参照してください:

- [`remote_write`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)。
- [`remote_read`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_read)。

## ルールファイル {#rules-files}

Prometheusは、[記録](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)および[アラート](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)ルールを許可します。

Linuxパッケージのインストールには、`/var/opt/gitlab/prometheus/rules/`に保存されている[デフォルトルールファイル](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/monitoring/templates/rules)が含まれています。

デフォルトルールをオーバーライドするには、`gitlab.rb.`でデフォルトリストを変更できます。

ルールなし:

```ruby
prometheus['rules_files'] = []
```

カスタムリスト:

```ruby
prometheus['rules_files'] = ['/path/to/rules/*.rules', '/path/to/single/file.rules']
```

## 外部ラベル {#external-labels}

[外部ラベル](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)を設定するには:

```ruby
prometheus['external_labels'] = {
    'region' => 'us-west-2',
    'source' => 'omnibus',
}
```

デフォルトでは外部ラベルは設定されません。

## `node_exporter` {#node_exporter}

`node_exporter`はシステムレベルのメトリクスを提供します。

追加のメトリクスコレクターはデフォルトで有効になっています。例えば、NFSマウントに関するメトリクスを収集するために`mountstats`が使用されます。

`mountstats`コレクターを無効にするには、`gitlab.rb`を以下の設定で調整し、`gitlab-ctl reconfigure`を実行します:

```ruby
node_exporter['flags'] = {
  'collector.mountstats' => false,
}
```

利用可能なコレクターの詳細については、[アップストリームのドキュメント](https://github.com/prometheus/node_exporter#collectors)を参照してください。

## Alertmanagerオプション {#alertmanager-options}

[Alertmanager](https://prometheus.io/docs/alerting/latest/configuration/)の[グローバルオプション](https://prometheus.io/docs/alerting/latest/configuration/)を設定できます。

例えば、以下の`gitlab.rb`設定は、AlertmanagerがSMTPサーバーに対して自身を識別するために使用するホスト名をオーバーライドします:

```ruby
alertmanager['global'] = {
  'smtp_hello' => 'example.org'
}
```

### 追加のレシーバーとルート {#additional-receivers-and-routes}

この例では、VictorOps用の新しいレシーバーを実装します。

1. `/etc/gitlab/gitlab.rb`を編集して、新しいレシーバーを追加し、[ルート](https://prometheus.io/docs/alerting/latest/configuration/#route)を定義します:

   ```ruby
   alertmanager['receivers'] = [
     {
       'name' => 'victorOps-receiver',
       'victorops_configs' => [
         {
           'routing_key'         => 'Sample_route',
           'api_key'             => '558e7ebc-XXXX-XXXX-XXXX-XXXXXXXXXXXX',
           'entity_display_name' => '{{ .CommonAnnotations.summary }}',
           'message_type'        => '{{ .CommonLabels.severity }}',
           'state_message'       => 'Alert: {{ .CommonLabels.alertname }}. Summary:{{ .CommonAnnotations.summary }}. RawData: {{ .CommonLabels }}',
           'http_config'         => {
             proxy_url: 'http://internet.proxy.com:3128'
           }
         } #, { Next receiver }
       ]
     }
   ]

   alertmanager['routes'] = [
     {
       'receiver'        => 'victorOps-receiver',
       'group_wait'      => '30s',
       'group_interval'  => '5m',
       'repeat_interval' => '3h',
       'matchers'        => [ 'severity = high' ]
     } #, { Next route }
   ]
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Alertmanagerは、`severity = high`のアラートを`victorops-receiver`にルーティングします。

[Alertmanager用VictorOpsオプション](https://help.splunk.com/en/splunk-observability-cloud/splunk-on-call/integrations-with-splunk-on-call/prometheus-integration-for-splunk-on-call)の詳細については、こちらをご覧ください。
