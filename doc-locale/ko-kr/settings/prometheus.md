---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Prometheus 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 원격 읽기/쓰기 {#remote-readwrite}

Prometheus는 원격 서비스로 읽기 및 쓰기를 지원합니다.

원격 읽기 또는 쓰기 서비스를 구성하려면 `gitlab.rb`에 다음을 포함할 수 있습니다.

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

구성 옵션에 대한 자세한 정보는 Prometheus 구성에 대한 정보를 참조하세요:

- [`remote_write`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write).
- [`remote_read`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_read).

## 규칙 파일 {#rules-files}

Prometheus는 [기록](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) 및 [경고](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) 규칙을 허용합니다.

Linux 패키지 설치에는 `/var/opt/gitlab/prometheus/rules/`에 저장되는 일부 [기본 규칙 파일](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/monitoring/templates/rules)이 포함됩니다.

기본 규칙을 재정의하려면 `gitlab.rb.`의 기본 목록을 변경할 수 있습니다.

규칙 없음:

```ruby
prometheus['rules_files'] = []
```

사용자 지정 목록:

```ruby
prometheus['rules_files'] = ['/path/to/rules/*.rules', '/path/to/single/file.rules']
```

## 외부 레이블 {#external-labels}

[외부 레이블](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)을 설정하려면:

```ruby
prometheus['external_labels'] = {
    'region' => 'us-west-2',
    'source' => 'omnibus',
}
```

기본적으로 외부 레이블이 설정되지 않습니다.

## `node_exporter` {#node_exporter}

`node_exporter`은 시스템 수준 메트릭을 제공합니다.

추가 메트릭 수집기는 기본적으로 활성화됩니다. 예를 들어 `mountstats`은 NFS 마운트에 대한 메트릭을 수집하는 데 사용됩니다.

`mountstats` 수집기를 비활성화하려면 `gitlab.rb`을 다음 설정으로 조정하고 `gitlab-ctl reconfigure`을 실행하세요:

```ruby
node_exporter['flags'] = {
  'collector.mountstats' => false,
}
```

사용 가능한 수집기에 대한 자세한 정보는 [업스트림 문서](https://github.com/prometheus/node_exporter#collectors)를 참조하세요.

## Alertmanager 옵션 {#alertmanager-options}

[전역 옵션](https://prometheus.io/docs/alerting/latest/configuration/) 을 [Alertmanager](https://prometheus.io/docs/alerting/latest/configuration/)에 설정할 수 있습니다.

예를 들어 다음 `gitlab.rb` 구성은 Alertmanager가 SMTP 서버에 자신을 식별하는 데 사용하는 호스트 이름을 재정의합니다:

```ruby
alertmanager['global'] = {
  'smtp_hello' => 'example.org'
}
```

### 추가 수신자 및 경로 {#additional-receivers-and-routes}

이 예제에서는 VictorOps의 새로운 수신자를 구현합니다.

1. `/etc/gitlab/gitlab.rb`을 편집하여 새로운 수신자를 추가하고 [경로](https://prometheus.io/docs/alerting/latest/configuration/#route)를 정의합니다:

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

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Alertmanager는 이제 `severity = high` 경고를 `victorops-receiver`로 라우팅합니다.

[VictorOps 문서](https://help.victorops.com/knowledge-base/victorops-prometheus-integration/)에서 Alertmanager의 VictorOps 옵션에 대해 자세히 알아보세요.
