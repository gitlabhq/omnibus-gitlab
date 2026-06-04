---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: NGINX 문제 해결
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[NGINX를 구성할](nginx.md) 때 다음 이슈가 발생할 수 있습니다.

## 오류: `400 Bad Request: too many Host headers` {#error-400-bad-request-too-many-host-headers}

`proxy_set_header` 구성이 `nginx['custom_gitlab_server_config']` 설정에 없는지 확인하는 것이 해결 방법입니다. 대신 [`proxy_set_headers`](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination) 구성을 `gitlab.rb` 파일에서 사용하십시오.

## 오류: `Received fatal alert: handshake_failure` {#error-received-fatal-alert-handshake_failure}

다음과 같은 오류가 나타날 수 있습니다:

```plaintext
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
```

이 이슈는 GitLab 인스턴스와 상호 작용하기 위해 이전 Java 기반 IDE 클라이언트를 사용할 때 발생합니다. 이러한 IDE는 TLS 1 프로토콜을 사용할 수 있으며, Linux 패키지 설치는 기본적으로 이를 지원하지 않습니다.

이 이슈를 해결하려면 서버의 암호를 업그레이드하십시오. [이슈 624](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/624#note_299061)의 사용자와 유사합니다.

이 서버 변경이 불가능한 경우 `/etc/gitlab/gitlab.rb`의 값을 변경하여 이전 동작으로 돌아갈 수 있습니다:

```ruby
nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3"
```

## 비공개 키와 인증서 간의 불일치 {#mismatch-between-private-key-and-certificate}

[NGINX 로그](https://docs.gitlab.com/administration/logs/#nginx-logs)에서 다음을 찾을 수 있습니다:

```plaintext
x509 certificate routines:X509_check_private_key:key values mismatch)
```

이 이슈는 비공개 키와 인증서 간에 불일치가 있을 때 발생합니다.

이를 해결하려면 올바른 비공개 키를 인증서와 일치시키십시오:

1. 올바른 키와 인증서가 있는지 확인하려면 비공개 키와 인증서의 모듈러스가 일치하는지 확인하십시오:

   ```shell
   /opt/gitlab/embedded/bin/openssl rsa -in /etc/gitlab/ssl/gitlab.example.com.key -noout -modulus | /opt/gitlab/embedded/bin/openssl sha256

   /opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/ssl/gitlab.example.com.crt -noout -modulus| /opt/gitlab/embedded/bin/openssl sha256
   ```

1. 일치하는지 확인한 후 NGINX를 다시 구성하고 다시 로드하십시오:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

## `Request Entity Too Large` {#request-entity-too-large}

[NGINX 로그](https://docs.gitlab.com/administration/logs/#nginx-logs)에서 다음을 찾을 수 있습니다:

```plaintext
Request Entity Too Large
```

이 오류는 요청이 허용된 최대 본문 크기를 초과할 때 발생합니다. 최근에 [최대 가져오기 크기](https://docs.gitlab.com/administration/settings/import_and_export_settings/#max-import-size)를 증가했다면 NGINX 구성도 업데이트해야 합니다.

이를 해결하려면 [`client_max_body_size`](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size) 지시문을 구성하십시오:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 클라이언트 최대 본문 크기 값을 증가시키십시오:

   ```ruby
   nginx['client_max_body_size'] = '250m'
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation).
1. [`HUP`](https://nginx.org/en/docs/control.html) NGINX를 사용하여 업데이트된 구성으로 정상적으로 다시 로드되도록 합니다:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

Kubernetes 설치의 경우 `client_max_body_size` 대신 [`proxyBodySize`](https://docs.gitlab.com/charts/charts/gitlab/webservice/#proxybodysize)를 구성하십시오.

## 보안 검사 경고: `NGINX HTTP Server Detection` {#security-scan-warning-nginx-http-server-detection}

이 이슈는 일부 보안 스캐너가 `Server: nginx` HTTP 헤더를 감지할 때 발생합니다. 대부분의 스캐너는 이 경고를 `Low` 또는 `Info` 심각도로 표시합니다. 예를 들어 [Nessus](https://www.tenable.com/plugins/nessus/106375)를 참조하십시오.

헤더 제거의 이점이 적고 그 존재가 [NGINX 프로젝트의 사용 통계 지원을 도우므로](https://trac.nginx.org/nginx/ticket/1644) 이 경고를 무시해야 합니다.

해결 방법은 `hide_server_tokens`을(를) 사용하여 헤더를 끄는 것입니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 값을 설정하십시오:

   ```ruby
   nginx['hide_server_tokens'] = 'on'
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation).
1. [`HUP`](https://nginx.org/en/docs/control.html) NGINX를 사용하여 업데이트된 구성으로 정상적으로 다시 로드되도록 합니다:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

## Web IDE 및 외부 NGINX를 사용할 때 브랜치를 찾을 수 없음 {#branch-not-found-when-using-web-ide-and-external-nginx}

다음과 같은 오류가 나타날 수 있습니다:

```plaintext
Branch 'branch_name' was not found in this project's repository
```

이 이슈는 NGINX 구성 파일의 `proxy_pass`에 슬래시가 후행할 때 발생합니다.

이를 해결하려면:

1. NGINX 구성 파일을 편집하여 `proxy_pass`에 후행 슬래시가 없도록 하십시오:

   ```plaintext
   proxy_pass https://1.2.3.4;
   ```

1. NGINX를 다시 시작하십시오:

   ```shell
   sudo systemctl restart nginx
   ```

## 오류: `worker_connections are not enough` {#error-worker_connections-are-not-enough}

GitLab에서 `502` 오류가 발생할 수 있으며 [NGINX 로그](https://docs.gitlab.com/administration/logs/#nginx-logs)에서 다음을 찾을 수 있습니다:

```plaintext
worker_connections are not enough
```

이 이슈는 워커 연결이 너무 낮은 값으로 설정되어 있을 때 발생합니다.

이를 해결하려면 NGINX 워커 연결을 더 높은 값으로 구성하십시오:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   gitlab['nginx']['worker_connections'] = 10240
   ```

   10240 연결이 [기본값](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/374b34e2bdc4bccb73665e0dc856ae32d6082d77/files/gitlab-cookbooks/gitlab/attributes/default.rb#L883)입니다.

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation). 변경 사항이 적용됩니다.
