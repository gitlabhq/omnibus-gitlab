---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Prometheus設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## リモート読み取り/書き込み {#remote-readwrite}

Prometheusは、リモートサービスとの間での読み取りと書き込みをサポートしています。

リモートの読み取りまたは書き込みサービスを設定するには、`gitlab.rb`に以下を含めることができます。

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

利用可能なオプションの詳細については、公式ドキュメントの[remote write](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cremote_write%3E)セクションと[remote read](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cremote_read%3E)セクションを参照してください。

## ルールファイル {#rules-files}

Prometheusでは、[recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)と[alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)のルールを使用できます。

Linuxパッケージのインストールには、`/var/opt/gitlab/prometheus/rules/`に保存されているいくつかの[デフォルトのルールファイル](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/monitoring/templates/rules)が含まれています。

デフォルトのルールをオーバーライドするには、`gitlab.rb.`でデフォルトのリストを変更します。

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

外部ラベルは、デフォルトでは設定されていません。

## `node_exporter` {#node_exporter}

`node_exporter`は、システムレベルのメトリクスを提供します。

追加のメトリクスコレクターは、デフォルトで有効になっています。たとえば、`mountstats`は、NFSマウントに関するメトリクスを収集するために使用されます。

`mountstats`コレクターを無効にするには、次の設定で`gitlab.rb`を調整し、`gitlab-ctl reconfigure`を実行します:

```ruby
node_exporter['flags'] = {
  'collector.mountstats' => false,
}
```

利用可能なコレクターの詳細については、[アップストリームドキュメント](https://github.com/prometheus/node_exporter#collectors)を参照してください。

## Alertmanagerオプション {#alertmanager-options}

[Alertmanager](https://prometheus.io/docs/alerting/latest/configuration/)の[グローバルオプション](https://prometheus.io/docs/alerting/latest/configuration/)を設定できます。

たとえば、次の`gitlab.rb`設定は、SMTPサーバー自体を識別するためにAlertmanagerが使用するホスト名をオーバーライドします:

```ruby
alertmanager['global'] = {
  'smtp_hello' => 'example.org'
}
```

### 追加のレシーバーとルート {#additional-receivers-and-routes}

この例では、VictorOpsの新しいレシーバーを実装します。

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

Alertmanagerは、`severity = high`アラートを`victorops-receiver`にルーティングするようになります。

AlertmanagerのVictorOpsオプションの詳細については、[VictorOpsのドキュメント](https://help.victorops.com/knowledge-base/victorops-prometheus-integration/)を参照してください。
