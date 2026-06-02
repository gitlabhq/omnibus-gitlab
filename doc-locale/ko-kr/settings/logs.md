---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 설치에서의 로그
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab에는 [고급 로그 시스템](https://docs.gitlab.com/administration/logs/)이 포함되어 있으며, GitLab 내의 모든 서비스 및 구성 요소가 시스템 로그를 출력합니다. 다음은 Linux 패키지 설치에서 이러한 로그를 관리하기 위한 구성 설정 및 도구입니다.

## 서버의 콘솔에서 로그 추적 {#tail-logs-in-a-console-on-the-server}

'tail'을 원하시는 경우, 즉 GitLab 로그의 실시간 업데이트를 보려면 `gitlab-ctl tail`을(를) 사용할 수 있습니다.

```shell
# Tail all logs; press Ctrl-C to exit
sudo gitlab-ctl tail

# Drill down to a sub-directory of /var/log/gitlab
sudo gitlab-ctl tail gitlab-rails

# Drill down to an individual file
sudo gitlab-ctl tail nginx/gitlab_error.log
```

### 콘솔에서 로그를 추적하고 파일에 저장 {#tail-logs-in-a-console-and-save-to-a-file}

콘솔에 로그를 표시하고 나중의 디버깅/분석을 위해 파일에 저장하는 것이 유용한 경우가 많습니다. [`tee`](https://en.wikipedia.org/wiki/Tee_(command)) 유틸리티를 사용하여 이를 수행할 수 있습니다.

```shell
# Use 'tee' to tail all the logs to STDOUT and write to a file at the same time
sudo gitlab-ctl tail | tee --append /tmp/gitlab_tail.log
```

## 기본 로그 디렉터리 구성 {#configure-default-log-directories}

`/etc/gitlab/gitlab.rb` 파일에는 다양한 유형의 로그에 대한 많은 `log_directory` 키가 있습니다. 다른 위치에 배치하려는 모든 로그의 주석을 제거하고 값을 업데이트하세요:

```ruby
# For example:
gitlab_rails['log_directory'] = "/var/log/gitlab/gitlab-rails"
puma['log_directory'] = "/var/log/gitlab/puma"
registry['log_directory'] = "/var/log/gitlab/registry"
...
```

Gitaly에는 다른 로그 디렉터리 구성이 있습니다:

```ruby
gitaly['configuration'] = {
   logging: {
    dir: "/var/log/gitlab/registry"
   }
}
```

`sudo gitlab-ctl reconfigure`을(를) 실행하여 이러한 설정으로 인스턴스를 구성하세요.

## runit 로그 {#runit-logs}

Linux 패키지 설치의 [runit 관리](../development/architecture/_index.md#runit) 서비스는 `svlogd`을(를) 사용하여 로그 데이터를 생성합니다.

- 로그는 `current`이라고 하는 파일에 기록됩니다.
- 주기적으로 이 로그는 TAI64N 형식을 사용하여 압축하고 이름을 바꾸며, 예를 들어 `@400000005f8eaf6f1a80ef5c.s`입니다.
- 압축된 로그의 파일 시스템 타임스탬프는 GitLab이 마지막으로 해당 파일에 기록한 시간과 일치합니다.
- `zmore` 및 `zgrep`을(를) 사용하면 압축되거나 압축되지 않은 로그를 모두 보고 검색할 수 있습니다.

[`svlogd` 설명서](https://smarden.org/runit/svlogd.8)를 읽어 생성되는 파일에 대해 자세히 알아보세요.

`svlogd` 설정을 `/etc/gitlab/gitlab.rb`에서 다음 설정으로 수정할 수 있습니다:

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

GitLab에 내장된 **logrotate** 서비스는 **runit**에서 캡처한 로그를 제외한 모든 로그를 관리합니다. 이 서비스는 `gitlab-rails/production.log` 및 `nginx/gitlab_access.log`와(과) 같은 로그 데이터를 회전, 압축 및 최종적으로 삭제합니다. 일반적인 logrotate 설정, 서비스별 logrotate 설정을 구성하고 `/etc/gitlab/gitlab.rb`를(을) 사용하여 logrotate를 완전히 비활성화할 수 있습니다.

### 일반 logrotate 설정 구성 {#configuring-common-logrotate-settings}

모든 **logrotate** 서비스에 공통인 설정을 `/etc/gitlab/gitlab.rb` 파일에서 설정할 수 있습니다. 이러한 설정은 각 서비스의 logrotate 구성 파일의 구성 옵션에 해당합니다. 자세한 내용은 logrotate 매뉴얼 페이지(`man logrotate`)를 참조하세요.

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

### 개별 서비스 logrotate 설정 구성 {#configuring-individual-service-logrotate-settings}

`/etc/gitlab/gitlab.rb`을(를) 사용하여 각 개별 서비스의 logrotate 설정을 사용자 지정할 수 있습니다. 예를 들어 `nginx` 서비스의 logrotate 빈도 및 크기를 사용자 지정하려면 다음을 사용하세요:

```ruby
nginx['logrotate_frequency'] = nil
nginx['logrotate_size'] = "200M"
```

### logrotate 비활성화 {#disabling-logrotate}

`/etc/gitlab/gitlab.rb`에서 다음 설정으로 내장 logrotate 서비스를 비활성화할 수도 있습니다:

```ruby
logrotate['enable'] = false
```

### Logrotate `notifempty` 설정 {#logrotate-notifempty-setting}

logrotate 서비스는 `notifempty`의 구성 불가능한 기본값으로 실행되어 다음 이슈를 해결합니다:

- 빈 로그가 불필요하게 회전되고 종종 많은 빈 로그가 저장됩니다.
- 장기 문제 해결에 유용한 일회성 로그가 데이터베이스 마이그레이션 로그와 같이 30일 후에 삭제됩니다.

### Logrotate 일회성 및 빈 로그 처리 {#logrotate-one-off-and-empty-log-handling}

이제 로그는 **logrotate**에 의해 필요에 따라 회전 및 다시 생성되며, 일회성 로그는 변경될 때만 회전됩니다. 이 설정이 적용되면 일부 정리 작업을 수행할 수 있습니다:

- `gitlab-rails/gitlab-rails-db-migrate*.log`과(와) 같은 빈 일회성 로그를 삭제할 수 있습니다.
- GitLab의 이전 버전에서 회전 및 압축된 빈 로그입니다. 이러한 빈 로그는 일반적으로 크기가 20바이트입니다.

### logrotate를 수동으로 실행 {#run-logrotate-manually}

Logrotate는 예약된 작업이지만 필요에 따라 트리거될 수도 있습니다.

`logrotate`을(를) 사용하여 GitLab 로그 회전을 수동으로 트리거하려면 다음 명령을 사용하세요:

```shell
/opt/gitlab/embedded/sbin/logrotate -fv -s /var/opt/gitlab/logrotate/logrotate.status /var/opt/gitlab/logrotate/logrotate.conf
```

### logrotate가 트리거되는 빈도를 높입니다 {#increase-how-often-logrotate-is-triggered}

logrotate 스크립트는 50분마다 트리거되고 로그를 회전하기 전에 10분 동안 대기합니다.

이러한 값을 수정하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   logrotate['pre_sleep'] = 600   # sleep 10 minutes before rotating after start-up
   logrotate['post_sleep'] = 3000 # wait 50 minutes after rotating
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## UDP 로그 전달 {#udp-log-forwarding}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Linux 패키지 설치는 svlogd의 UDP 로깅 기능을 활용하고 UDP를 사용하여 non-svlogd 로그를 syslog 호환 원격 시스템으로 보낼 수 있습니다. UDP를 통해 syslog 프로토콜 메시지를 보내도록 Linux 패키지 설치를 구성하려면 다음 설정을 사용하세요:

```ruby
logging['udp_log_shipping_host'] = '1.2.3.4' # Your syslog server
# logging['udp_log_shipping_hostname'] = nil # Optional, defaults the system hostname
logging['udp_log_shipping_port'] = 1514 # Optional, defaults to 514 (syslog)
```

> [!note]
> `udp_log_shipping_host` 설정은 [`svlogd_prefix`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/logging.rb) 을(를) 추가하여 각 [runit 관리](../development/architecture/_index.md#runit) 서비스에 대해 지정된 호스트명과 서비스를 위해 추가합니다.

예제 로그 메시지:

```plaintext
Jun 26 06:33:46 ubuntu1204-test production.log: Started GET "/root/my-project/import" for 127.0.0.1 at 2014-06-26 06:33:46 -0700
Jun 26 06:33:46 ubuntu1204-test production.log: Processing by ProjectsController#import as HTML
Jun 26 06:33:46 ubuntu1204-test production.log: Parameters: {"id"=>"root/my-project"}
Jun 26 06:33:46 ubuntu1204-test production.log: Completed 200 OK in 122ms (Views: 71.9ms | ActiveRecord: 12.2ms)
Jun 26 06:33:46 ubuntu1204-test gitlab_access.log: 172.16.228.1 - - [26/Jun/2014:06:33:46 -0700] "GET /root/my-project/import HTTP/1.1" 200 5775 "https://172.16.228.169/root/my-project/import" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36"
2014-06-26_13:33:46.49866 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7nbj0 Sidekiq::Extensions::DelayedMailer JID-bbfb118dd1db20f6c39f5b50 INFO: start
2014-06-26_13:33:46.52608 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7muoc RepositoryImportWorker JID-57ee926c3655fcfa062338ae INFO: start
```

## 사용자 지정 NGINX 로그 형식 사용 {#using-a-custom-nginx-log-format}

기본적으로 NGINX 액세스 로그는 쿼리 문자열에 포함된 잠재적으로 민감한 정보를 숨기도록 설계된 'combined' NGINX 형식의 버전을 사용합니다. 사용자 지정 로그 형식 문자열을 사용하려면 `/etc/gitlab/gitlab.rb`에서 지정할 수 있습니다. 형식 세부 정보는 [NGINX 설명서](https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format)를 참조하세요.

```ruby
nginx['log_format'] = 'my format string $foo $bar'
```

## JSON 로깅 {#json-logging}

구조화된 로그는 Elasticsearch, Splunk 또는 다른 로그 관리 시스템에서 구문 분석할 수 있도록 JSON을 통해 내보낼 수 있습니다. JSON 형식은 기본적으로 이를 지원하는 모든 서비스에 대해 활성화됩니다.

> [!note]
> PostgreSQL은 외부 플러그인 없이 JSON 로깅을 지원하지 않습니다. 그러나 CSV 형식의 로깅을 지원합니다:

```ruby
postgresql['log_destination'] = 'csvlog'
postgresql['logging_collector'] = 'on'
```

이 설정이 적용되려면 데이터베이스를 다시 시작해야 합니다. 자세한 내용은 [PostgreSQL 문서](https://www.postgresql.org/docs/12/runtime-config-logging.html)를 참조하세요.

## 텍스트 로깅 {#text-logging}

확립된 로그 수집 시스템이 있는 고객은 JSON 로그 형식을 사용하지 않을 수 있습니다. 텍스트 형식은 `/etc/gitlab/gitlab.rb`에서 다음을 설정하고 그 후 `gitlab-ctl reconfigure`을(를) 실행하여 구성할 수 있습니다:

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
> 로그 형식의 속성 이름에는 서비스 관련에 따라 몇 가지 변형이 있습니다(예: 컨테이너 레지스트리는 `log_formatter`을(를) 사용하고, Gitaly와 Praefect는 모두 `logging_format`을(를) 사용합니다). 자세한 내용은 [이슈 #4280](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4280)을(를) 참조하세요.

## rbtrace {#rbtrace}

GitLab은 [`rbtrace`](https://github.com/tmm1/rbtrace)와(과) 함께 제공되며, Ruby 코드를 추적하고, 실행 중인 모든 스레드를 보고, 메모리 덤프를 생성할 수 있습니다. 그러나 이는 기본적으로 활성화되지 않습니다. 활성화하려면 `ENABLE_RBTRACE` 변수를 환경으로 정의하세요:

```ruby
gitlab_rails['env'] = {"ENABLE_RBTRACE" => "1"}
```

그런 다음 시스템을 다시 구성하고 Puma와 Sidekiq을 다시 시작하세요. Linux 패키지 설치에서 이를 실행하려면 루트로 실행하세요:

```ruby
/opt/gitlab/embedded/bin/ruby /opt/gitlab/embedded/bin/rbtrace
```

## 로그 수준/상세 정도 구성 {#configuring-log-levelverbosity}

GitLab Rails, 컨테이너 레지스트리, GitLab Shell 및 Gitaly의 최소 로그 수준(상세 정도)을 구성할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 로그 수준을 설정하세요:

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

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 특정 GitLab 로그(예: `production_json.log`, `graphql_json.log` 등)에 대해 `log_level`을(를) [편집할 수 없습니다](https://gitlab.com/groups/gitlab-org/-/epics/6034). [기본 로그 수준 재정의](https://docs.gitlab.com/administration/logs/#override-default-log-level)도 참조하세요.

## 사용자 지정 로그 그룹 설정 {#setting-a-custom-log-group}

GitLab은 구성된 [로그 디렉터리](#configure-default-log-directories)에 사용자 지정 그룹을 할당할 수 있습니다.

`logging['log_group']` 전역 설정을 `/etc/gitlab/gitlab.rb` 파일에서 구성할 수 있으며, `gitaly['log_group']`와(과) 같은 `log_group` 설정별 서비스도 구성할 수 있습니다. `log_group` 설정을 추가할 때 인스턴스를 구성하기 위해 `sudo gitlab-ctl reconfigure`을(를) 실행해야 합니다.

전역 또는 서비스별 `log_group`을(를) 설정하면:

- 서비스별 로그 디렉터리(또는 전역 설정을 사용하는 경우 모든 로그 디렉터리)의 권한을 `0750`로 변경하여 구성된 그룹 멤버가 로그 디렉터리의 내용을 읽을 수 있도록 합니다.
- [runit](#runit-logs)을(를) 지정된 `log_group`을(를) 사용하여 로그를 쓰고 회전하도록 구성합니다: 서비스별 또는 모든 runit 관리 서비스입니다.

### 사용자 지정 로그 그룹 제한 사항 {#custom-log-group-limitations}

runit에 의해 관리되지 않는 서비스의 로그(예: `/var/log/gitlab/gitlab-rails`의 `gitlab-rails` 로그)는 구성된 `log_group` 설정을 상속하지 않습니다.

그룹은 이미 호스트에 있어야 합니다. Linux 패키지 설치는 `sudo gitlab-ctl reconfigure`을(를) 실행할 때 그룹을 생성하지 않습니다.
