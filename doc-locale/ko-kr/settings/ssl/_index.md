---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 설치를 위한 SSL 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Linux 패키지는 SSL 구성을 위한 여러 일반적인 사용 사례를 지원합니다.

기본적으로 HTTPS는 활성화되지 않습니다. HTTPS를 활성화하려면 다음을 수행할 수 있습니다:

- 무료로 자동화된 HTTPS를 위해 Let's Encrypt를 사용합니다.
- 자신의 인증서를 사용하여 수동으로 HTTPS를 구성합니다.

> [!note]
> 프록시, 로드 밸런서 또는 다른 외부 장치를 사용하여 GitLab 호스트 이름에 대한 SSL을 종료하는 경우 [외부, 프록시 및 로드 밸런서 SSL 종료](#configure-a-reverse-proxy-or-load-balancer-ssl-termination)를 참고하세요.

다음 표는 각 GitLab 서비스가 지원하는 방법을 보여줍니다.

| 서비스                | 수동 SSL                                                                                                                   | Let's Encrypt 통합 |
|------------------------|------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| GitLab 인스턴스 도메인 | [예](#configure-https-manually)                                                                                             | [예](#enable-the-lets-encrypt-integration) |
| 컨테이너 레지스트리     | [예](https://docs.gitlab.com/administration/packages/container_registry/#configure-container-registry-under-its-own-domain) | [예](#enable-the-lets-encrypt-integration) |
| GitLab Pages           | [예](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support)                                       | [예](#enable-the-lets-encrypt-integration)                        |

## OpenSSL 3 업그레이드 {#openssl-3-upgrade}

[버전 17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770)부터 GitLab은 OpenSSL 3을 사용합니다. 일부 이전 TLS 프로토콜 및 암호 제품군, 또는 외부 통합을 위한 더 약한 TLS 인증서는 OpenSSL 3 기본값과 호환되지 않을 수 있습니다.

GitLab 17.7로 업그레이드하기 전에 [OpenSSL 3 가이드](openssl_3.md)를 사용하여 외부 통합의 호환성을 식별하고 평가합니다.

GitLab 17.7로 업그레이드한 후 다음 명령으로 GitLab이 OpenSSL 3을 사용하고 있는지 확인할 수 있습니다:

```shell
/opt/gitlab/embedded/bin/openssl version
```

## Let's Encrypt 통합 활성화 {#enable-the-lets-encrypt-integration}

[Let's Encrypt](https://letsencrypt.org)는 `external_url`이 HTTPS 프로토콜로 설정되고 다른 인증서가 구성되지 않은 경우 기본적으로 활성화됩니다.

전제 조건:

- 포트 `80`과 `443`는 검증 확인을 실행하는 공개 Let's Encrypt 서버에 액세스할 수 있어야 합니다. 검증은 [비표준 포트로 작동하지 않습니다](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3580). 환경이 비공개이거나 에어갭된 경우 Let's Encrypt에서 사용하는 도구인 certbot은 Let's Encrypt 인증서를 설치하는 [수동 방법](https://eff-certbot.readthedocs.io/en/stable/using.html#manual)을 제공합니다.

Let's Encrypt를 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 항목을 추가하거나 변경합니다:

   ```ruby
   ## GitLab instance
   external_url "https://gitlab.example.com"         # Must use https protocol
   letsencrypt['contact_emails'] = ['foo@email.com'] # Optional

   ## Container Registry (optional), must use https protocol
   registry_external_url "https://registry.example.com"
   #registry_nginx['ssl_certificate'] = "path/to/cert"      # Must be absent or commented out

   ## GitLab Pages (optional), must use https protocol
   pages_external_url "https://pages.example.com"
   gitlab_pages['namespace_in_path'] = true      # Required to enable single-domain sites
   ```

   - 인증서는 90일마다 만료됩니다. `contact_emails`에 지정하는 이메일 주소는 만료 날짜가 가까워지면 알림을 받습니다.
   - GitLab 인스턴스는 인증서의 기본 도메인 이름입니다. 컨테이너 레지스트리 같은 추가 서비스는 동일한 인증서에 대체 도메인 이름으로 추가됩니다. 위 예에서 기본 도메인은 `gitlab.example.com`이고 컨테이너 레지스트리 도메인은 `registry.example.com`입니다. 와일드카드 인증서를 설정할 필요는 없습니다.

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Let's Encrypt가 인증서 발급에 실패한 경우 가능한 솔루션에 대해 [이슈 해결 섹션](ssl_troubleshooting.md#lets-encrypt-fails-on-reconfigure)을 참고하세요.

### 인증서를 자동으로 갱신 {#renew-the-certificates-automatically}

기본 설치는 매월 4일 자정 이후에 갱신을 예약합니다. 분은 `external_url`의 값으로 결정되어 업스트림 Let's Encrypt 서버의 로드를 분산하는 데 도움이 됩니다.

갱신 시간을 명시적으로 설정하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Renew every 7th day of the month at 12:30
   letsencrypt['auto_renew_hour'] = "12"
   letsencrypt['auto_renew_minute'] = "30"
   letsencrypt['auto_renew_day_of_month'] = "*/7"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 인증서는 30일 이내에 만료될 때만 갱신됩니다. 예를 들어 매월 1일 00:00에 갱신하도록 설정하고 인증서가 31일에 만료되는 경우 인증서가 갱신되기 전에 만료됩니다.

자동 갱신은 [go-crond](https://github.com/webdevops/go-crond)로 관리됩니다. 원하는 경우 `/etc/gitlab/gitlab.rb`을 편집하여 [CLI 인수](https://github.com/webdevops/go-crond#usage)를 go-crond에 전달할 수 있습니다:

```ruby
crond['flags'] = {
  'log.json' = true,
  'server.bind' = ':8040'
}
```

자동 갱신을 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   letsencrypt['auto_renew'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 인증서를 수동으로 갱신 {#renew-the-certificates-manually}

다음 명령 중 하나를 사용하여 Let's Encrypt 인증서를 수동으로 갱신합니다:

```shell
sudo gitlab-ctl reconfigure
```

```shell
sudo gitlab-ctl renew-le-certs
```

이전 명령은 인증서가 만료에 가까울 때만 갱신을 생성합니다. 갱신 중 오류가 발생하면 [업스트림 속도 제한을 고려하세요](https://letsencrypt.org/docs/rate-limits/).

### Let's Encrypt 이외의 ACME 서버 사용 {#use-an-acme-server-other-than-lets-encrypt}

Let's Encrypt 이외의 ACME 서버를 사용하고 인증서를 가져올 수 있도록 GitLab을 구성할 수 있습니다. 자신의 ACME 서버를 제공하는 일부 서비스는 다음과 같습니다:

- [ZeroSSL](https://zerossl.com/documentation/acme/)
- [Buypass](https://www.buypass.com/products/tls-ssl-certificates/go-ssl)
- [SSL.com](https://www.ssl.com/guide/ssl-tls-certificate-issuance-and-revocation-with-acme/)
- [`step-ca`](https://smallstep.com/docs/step-ca/index.html)

사용자 지정 ACME 서버를 사용하도록 GitLab을 구성하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하고 ACME 엔드포인트를 설정합니다:

   ```ruby
   external_url 'https://example.com'
   letsencrypt['acme_staging_endpoint'] = 'https://ca.internal/acme/acme/directory'
   letsencrypt['acme_production_endpoint'] = 'https://ca.internal/acme/acme/directory'
   ```

   사용자 지정 ACME 서버가 제공하는 경우 스테이징 엔드포인트도 사용합니다. 스테이징 엔드포인트를 먼저 확인하면 ACME 프로덕션에 요청을 제출하기 전에 ACME 구성이 올바른지 확인할 수 있습니다. 구성 작업을 하는 동안 ACME 속도 제한을 방지하기 위해 이를 수행합니다.

   기본값은 다음과 같습니다:

   ```plaintext
   https://acme-staging-v02.api.letsencrypt.org/directory
   https://acme-v02.api.letsencrypt.org/directory
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 인증서에 대체 도메인 추가 {#add-alternative-domains-to-the-certificate}

기본적으로 GitLab은 인증서의 CN(공통 이름)과 SAN(주체 대체 이름)을 `external_url`에 지정된 호스트 이름으로 설정합니다.

Let's Encrypt 인증서에 추가 대체 도메인(또는 주체 대체 이름)을 추가할 수 있습니다. [번들 NGINX](../nginx.md) 를 [다른 백엔드 애플리케이션의 역방향 프록시](../nginx.md#insert-custom-settings-into-the-nginx-configuration)로 사용하고 싶다면 도움이 될 수 있습니다.

대체 도메인의 DNS 레코드는 GitLab 인스턴스를 가리켜야 합니다. `external_url` 호스트 이름은 주체 대체 이름 목록에 포함되어야 합니다.

Let's Encrypt 인증서에 대체 도메인을 추가하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하고 대체 도메인을 추가합니다:

   ```ruby
   # Separate multiple domains with commas
   letsencrypt['alt_names'] = ['gitlab.example.com', 'another-application.example.com']
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

메인 GitLab 애플리케이션에 대해 생성된 결과 Let's Encrypt 인증서에는 지정된 대체 도메인이 포함됩니다. 생성된 파일은 다음 위치에 있습니다:

- `/etc/gitlab/ssl/gitlab.example.com.key` 파일은 키입니다.
- `/etc/gitlab/ssl/gitlab.example.com.crt` 파일은 인증서입니다.

## HTTPS 수동 구성 {#configure-https-manually}

> [!warning]
> NGINX 구성은 브라우저 및 클라이언트에 다음 365일 동안 [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security)를 사용하여 GitLab 인스턴스와만 보안 연결을 통해 통신하도록 지시합니다. 더 많은 구성 옵션은 [HTTP Strict Transport Security 구성](#configure-the-http-strict-transport-security-hsts)을 참고하세요. HTTPS를 활성화하는 경우 인스턴스에 최소 24개월 동안 보안 연결을 제공해야 합니다.

HTTPS를 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:
   1. `external_url`을 도메인으로 설정합니다. URL의 `https`를 주의하세요:

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   1. Let's Encrypt 통합을 비활성화합니다:

      ```ruby
      letsencrypt['enable'] = false
      ```

      GitLab은 재구성할 때마다 Let's Encrypt 인증서를 갱신하려고 시도합니다. 수동으로 생성한 인증서를 사용할 계획이라면 Let's Encrypt 통합을 비활성화해야 합니다. 그렇지 않으면 자동 갱신으로 인해 인증서를 덮어쓸 수 있습니다.

1. `/etc/gitlab/ssl` 디렉터리를 생성하고 키 및 인증서를 복사합니다:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp gitlab.example.com.key gitlab.example.com.crt /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/gitlab.example.com.crt
   sudo chmod 600 /etc/gitlab/ssl/gitlab.example.com.key
   ```

   예에서 호스트 이름은 `gitlab.example.com`이므로 Linux 패키지 설치는 `/etc/gitlab/ssl/gitlab.example.com.key` 및 `/etc/gitlab/ssl/gitlab.example.com.crt`이라는 개인 키 및 공용 인증서 파일을 찾습니다. 원할 경우 [다른 위치 및 인증서 이름을 사용](#change-the-default-ssl-certificate-location)할 수 있습니다.

   클라이언트가 연결할 때 SSL 오류를 방지하기 위해 전체 인증서 체인을 올바른 순서대로 사용해야 합니다: 먼저 서버 인증서, 그 다음 모든 중간 인증서, 마지막으로 루트 CA입니다.

1. 선택 사항입니다. `certificate.key` 파일이 암호로 보호되어 있으면 GitLab을 재구성할 때 NGINX가 암호를 요청하지 않습니다. 이 경우 Linux 패키지 설치가 오류 메시지 없이 무음으로 실패합니다.

   키 파일의 암호를 지정하려면 텍스트 파일(예: `/etc/gitlab/ssl/key_file_password.txt`)에 암호를 저장하고 `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   nginx['ssl_password_file'] = '/etc/gitlab/ssl/key_file_password.txt'
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 선택 사항입니다. 방화벽을 사용하는 경우 포트 443을 열어 인바운드 HTTPS 트래픽을 허용해야 할 수 있습니다:

   ```shell
   # UFW example (Debian, Ubuntu)
   sudo ufw allow https

   # lokkit example (RedHat, CentOS 6)
   sudo lokkit -s https

   # firewall-cmd (RedHat, Centos 7)
   sudo firewall-cmd --permanent --add-service=https
   sudo systemctl reload firewalld
   ```

기존 인증서를 업데이트하는 경우 [다른 프로세스](#update-the-ssl-certificates)를 따릅니다.

### `HTTP` 요청을 `HTTPS`로 리디렉션 {#redirect-http-requests-to-https}

기본적으로 `external_url`이 `https`로 시작되는 것을 지정하면 NGINX는 더 이상 포트 80에서 암호화되지 않은 HTTP 트래픽을 수신 대기하지 않습니다. 모든 HTTP 트래픽을 HTTPS로 리디렉션하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['redirect_http_to_https'] = true
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 이 동작은 [Let's Encrypt 통합](#enable-the-lets-encrypt-integration)을 사용할 때 기본적으로 활성화됩니다.

### 기본 HTTPS 포트 변경 {#change-the-default-https-port}

기본(443) 이외의 HTTPS 포트를 사용해야 하는 경우 `external_url`의 일부로 지정합니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   external_url "https://gitlab.example.com:2443"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 기본 SSL 인증서 위치 변경 {#change-the-default-ssl-certificate-location}

호스트 이름이 `gitlab.example.com`인 경우 Linux 패키지 설치는 기본적으로 `/etc/gitlab/ssl/gitlab.example.com.key` 및 `/etc/gitlab/ssl/gitlab.example.com.crt`이라는 개인 키와 공용 인증서를 찾습니다.

SSL 인증서의 다른 위치를 설정하려면:

1. 디렉터리를 생성하고, 적절한 권한을 부여하고, `.crt` 및 `.key` 파일을 디렉터리에 배치합니다:

   ```shell
   sudo mkdir -p /mnt/gitlab/ssl
   sudo chmod 755 /mnt/gitlab/ssl
   sudo cp gitlab.key gitlab.crt /mnt/gitlab/ssl/
   ```

   클라이언트가 연결할 때 SSL 오류를 방지하기 위해 전체 인증서 체인을 올바른 순서대로 사용해야 합니다: 먼저 서버 인증서, 그 다음 모든 중간 인증서, 마지막으로 루트 CA입니다.

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['ssl_certificate'] = "/mnt/gitlab/ssl/gitlab.crt"
   nginx['ssl_certificate_key'] = "/mnt/gitlab/ssl/gitlab.key"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### SSL 인증서 업데이트 {#update-the-ssl-certificates}

SSL 인증서 콘텐츠는 업데이트되었지만 `/etc/gitlab/gitlab.rb`에 대한 구성 변경이 없는 경우 GitLab을 재구성하면 NGINX에 영향을 주지 않습니다. 대신 NGINX가 [기존 구성 및 새 인증서를 다시 로드](http://nginx.org/en/docs/control.html)하도록 해야 합니다:

```shell
sudo gitlab-ctl hup nginx
sudo gitlab-ctl hup registry
```

## 역방향 프록시 또는 로드 밸런서 SSL 종료 구성 {#configure-a-reverse-proxy-or-load-balancer-ssl-termination}

기본적으로 Linux 패키지 설치는 `external_url`이 `https://`를 포함하면 SSL 사용 여부를 자동 감지하고 NGINX를 SSL 종료로 구성합니다. 그러나 GitLab이 역방향 프록시 또는 외부 로드 밸런서 뒤에서 실행되도록 구성한 경우 일부 환경에서는 GitLab 애플리케이션 외부에서 SSL을 종료하고 싶을 수 있습니다.

번들 NGINX가 SSL 종료를 처리하지 않도록 하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['listen_port'] = 80
   nginx['listen_https'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

외부 로드 밸런서는 `200` 상태 코드를 반환하는 GitLab 엔드포인트에 액세스해야 할 수 있습니다(로그인이 필요한 설치의 경우 루트 페이지는 로그인 페이지로 `302` 리디렉션을 반환합니다). 이 경우 [상태 확인 엔드포인트](https://docs.gitlab.com/administration/monitoring/health_check/)를 활용하는 것이 좋습니다.

컨테이너 레지스트리 또는 GitLab Pages 같은 다른 번들 구성 요소는 프록시된 SSL에 유사한 전략을 사용합니다. 특정 구성 요소의 `*_external_url`을 `https://`로 설정하고 `nginx[...]` 구성에 구성 요소 이름을 접두사로 붙입니다. 예를 들어 GitLab 컨테이너 레지스트리 구성에는 `registry_` 접두사가 붙습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   registry_external_url 'https://registry.example.com'

   registry_nginx['listen_port'] = 80
   registry_nginx['listen_https'] = false
   ```

   Pages에는 동일한 형식을 사용할 수 있습니다(`pages_` 접두사).

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 선택 사항입니다. 역방향 프록시 또는 로드 밸런서를 구성하여 특정 헤더(예: `Host`, `X-Forwarded-Ssl`, `X-Forwarded-For`, `X-Forwarded-Port`)를 GitLab으로 전달해야 할 수 있습니다. 이 단계를 건너뛰면 "422 Unprocessable Entity" 또는 "Can't verify CSRF token authenticity" 같은 부정확한 리디렉션 또는 오류가 표시될 수 있습니다.

AWS Certificate Manager(ACM) 같은 일부 클라우드 공급자 서비스는 인증서 다운로드를 허용하지 않습니다. 이는 GitLab 인스턴스에서 종료하는 데 사용되는 것을 방지합니다. SSL이 클라우드 서비스와 GitLab 간에 필요한 경우 GitLab 인스턴스에서 다른 인증서를 사용해야 합니다.

## 사용자 지정 SSL 암호 사용 {#use-custom-ssl-ciphers}

기본적으로 Linux 패키지는 [SSL 암호를 사용](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/0482fb343a4434ba3a2523a7fb576d2bbb2a3f5f/files/gitlab-cookbooks/gitlab/attributes/default.rb#L876)하며, 이는 <https://gitlab.com>에 대한 테스트 및 GitLab 커뮤니티에서 제공한 다양한 모범 사례의 조합입니다.

SSL 암호를 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['ssl_ciphers'] = "CIPHER:CIPHER1"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`ssl_dhparam` 지시어를 활성화하려면:

1. `dhparams.pem`을 생성합니다:

   ```shell
   openssl dhparam -out /etc/gitlab/ssl/dhparams.pem 2048
   ```

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparams.pem"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## HTTP/2 프로토콜 구성 {#configure-the-http2-protocol}

기본적으로 GitLab 인스턴스가 HTTPS를 통해 도달 가능함을 지정하면 [HTTP/2 프로토콜](https://www.rfc-editor.org/rfc/rfc7540)도 활성화됩니다.

Linux 패키지는 HTTP/2 프로토콜과 호환되는 필수 SSL 암호를 설정합니다.

자신의 [사용자 지정 SSL 암호](#use-custom-ssl-ciphers) 를 지정하고 암호가 [HTTP/2 암호 블랙리스트](https://www.rfc-editor.org/rfc/rfc7540#appendix-A)에 있으면 GitLab 인스턴스에 접근하려고 할 때 브라우저에 `INADEQUATE_SECURITY` 오류가 표시됩니다. 이 경우 암호 목록에서 문제가 있는 암호를 제거하는 것을 고려하세요. 암호를 변경하는 것은 매우 특정한 사용자 지정 설정이 있는 경우에만 필요합니다.

HTTP/2 프로토콜을 활성화하려는 이유에 대한 자세한 정보는 [NGINX HTTP/2 백서](https://cdn.awstatic.com/pub/NGINX_HTTP2_White_Paper_v4.pdf)를 참고하세요.

암호를 변경하는 것이 옵션이 아닌 경우 HTTP/2 지원을 비활성화할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['http2_enabled'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> HTTP/2 설정은 메인 GitLab 애플리케이션에만 작동하며 GitLab Pages 및 컨테이너 레지스트리 같은 다른 서비스에는 작동하지 않습니다.

## 2방향 SSL 클라이언트 인증 활성화 {#enable-2-way-ssl-client-authentication}

웹 클라이언트가 신뢰할 수 있는 인증서로 인증하도록 요구하려면 2방향 SSL을 활성화할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['ssl_verify_client'] = "on"
   nginx['ssl_client_certificate'] = "/etc/pki/tls/certs/root-certs.pem"
   ```

1. 선택 사항입니다. NGINX가 클라이언트에 유효한 인증서가 없다고 결정하기 전에 인증서 체인에서 얼마나 깊이 확인해야 하는지 구성할 수 있습니다(기본값은 `1`). `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['ssl_verify_depth'] = "2"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## HTTP Strict Transport Security(HSTS) 구성 {#configure-the-http-strict-transport-security-hsts}

> [!note]
> HSTS 설정은 메인 GitLab 애플리케이션에만 작동하며 GitLab Pages 및 컨테이너 레지스트리 같은 다른 서비스에는 작동하지 않습니다.

HTTP Strict Transport Security(HSTS)는 기본적으로 활성화되며 브라우저에 HTTPS만 사용하여 웹 사이트에 접속해야 함을 알립니다. 브라우저가 GitLab 인스턴스를 방문하면 사용자가 명시적으로 일반 HTTP URL(`http://`)을 입력할 때도 더 이상 안전하지 않은 연결을 시도하지 않도록 기억합니다. 일반 HTTP URL은 브라우저에 의해 `https://` 변형으로 자동으로 리디렉션됩니다.

기본적으로 `max_age`은 2년으로 설정되어 있으며, 이는 브라우저가 HTTPS를 통해서만 연결하기로 기억할 기간입니다.

최대 나이 값을 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['hsts_max_age'] = 63072000
   nginx['hsts_include_subdomains'] = false
   ```

   `max_age`을 `0`로 설정하면 HSTS가 비활성화됩니다.

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

HSTS 및 NGINX에 대한 자세한 정보는 <https://blog.nginx.org/blog/http-strict-transport-security-hsts-and-nginx>을 참고하세요.

## 사용자 지정 공용 인증서 설치 {#install-custom-public-certificates}

일부 환경에서는 다양한 작업을 위해 외부 리소스에 연결하며 GitLab은 이러한 연결에서 HTTPS를 사용할 수 있도록 하고 자체 서명된 인증서를 지원합니다. GitLab은 자체 ca-cert 번들을 가지고 있으며, `/etc/gitlab/trusted-certs` 디렉터리에 개별 사용자 지정 인증서를 배치하여 인증서를 추가할 수 있습니다. 그러면 번들에 추가됩니다. `openssl rehash` 명령을 사용하여 추가되며, 이는 [단일 인증서](#using-a-custom-certificate-chain)에서만 작동합니다.

Linux 패키지는 인증서 신뢰성을 확인하는 데 사용되는 신뢰할 수 있는 루트 인증 기관의 공식 [Mozilla](https://wiki.mozilla.org/CA/Included_Certificates) 컬렉션을 제공합니다.

> [!note]
> 자체 서명된 인증서를 사용하는 설치의 경우 Linux 패키지는 이러한 인증서를 관리하는 방법을 제공합니다. 이것이 어떻게 작동하는지에 대한 자세한 기술 정보는 이 페이지 하단의 [세부 사항](#details-on-how-gitlab-and-ssl-work)을 참고하세요.

사용자 지정 공용 인증서를 설치하려면:

1. 개인 키 인증서에서 **PEM** 또는 **DER** 인코딩된 공용 인증서를 생성합니다.
1. 공용 인증서 파일만 `/etc/gitlab/trusted-certs` 디렉터리에 복사합니다. 다중 노드 설치가 있는 경우 모든 노드에 인증서를 복사해야 합니다.
   - GitLab이 사용자 지정 공용 인증서를 사용하도록 구성할 때 기본적으로 GitLab은 GitLab 도메인 이름 뒤에 `.crt` 확장자를 가진 인증서를 찾으려고 예상합니다. 예를 들어 서버 주소가 `https://gitlab.example.com`인 경우 인증서는 `gitlab.example.com.crt`이라고 이름을 지정해야 합니다.
   - GitLab이 사용자 지정 공용 인증서를 사용하는 외부 리소스에 연결해야 하는 경우 `/etc/gitlab/trusted-certs` 디렉터리에 `.crt` 확장자로 인증서를 저장합니다. 관련 외부 리소스의 도메인 이름을 기반으로 파일 이름을 지정할 필요는 없지만 일관된 명명 스키마를 사용하는 것이 좋습니다.

   다른 경로 및 파일 이름을 지정하려면 [기본 SSL 인증서 위치를 변경](#change-the-default-ssl-certificate-location)할 수 있습니다.

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 사용자 지정 인증서 체인 사용 {#using-a-custom-certificate-chain}

[알려진 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/1425) 때문에 사용자 지정 인증서 체인을 사용하는 경우 서버, 중간 및 루트 인증서를 `/etc/gitlab/trusted-certs` 디렉터리의 별도 파일에 **must**.

이는 GitLab 자체 또는 GitLab이 연결해야 하는 외부 리소스가 사용자 지정 인증서 체인을 사용하는 두 경우 모두에 적용됩니다.

예를 들어 GitLab 자체의 경우 다음을 사용할 수 있습니다:

- `/etc/gitlab/trusted-certs/example.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_root.crt`

GitLab이 연결해야 하는 외부 리소스의 경우 다음을 사용할 수 있습니다:

- `/etc/gitlab/trusted-certs/external-service.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_root.crt`

## GitLab 및 SSL이 작동하는 방식에 대한 세부 사항 {#details-on-how-gitlab-and-ssl-work}

Linux 패키지에는 자체 OpenSSL 라이브러리가 포함되어 있으며 모든 컴파일된 프로그램(예: Ruby, PostgreSQL 등)이 이 라이브러리에 연결됩니다. 이 라이브러리는 `/opt/gitlab/embedded/ssl/certs`에서 인증서를 찾도록 컴파일됩니다.

Linux 패키지는 `/etc/gitlab/trusted-certs/`에 추가된 모든 인증서를 `/opt/gitlab/embedded/ssl/certs`로 기호적으로 연결하여 사용자 지정 인증서를 관리합니다. [openssl rehash](https://docs.openssl.org/3.1/man1/openssl-rehash/) 도구를 사용합니다. 예를 들어 `customcacert.pem`을 `/etc/gitlab/trusted-certs/`에 추가한다고 가정해봅시다:

```shell
$ sudo ls -al /opt/gitlab/embedded/ssl/certs

total 272
drwxr-xr-x 2 root root   4096 Jul 12 04:19 .
drwxr-xr-x 4 root root   4096 Jul  6 04:00 ..
lrwxrwxrwx 1 root root     42 Jul 12 04:19 7f279c95.0 -> /etc/gitlab/trusted-certs/customcacert.pem
-rw-r--r-- 1 root root 263781 Jul  5 17:52 cacert.pem
-rw-r--r-- 1 root root    147 Feb  6 20:48 README
```

여기서 인증서의 지문은 `7f279c95`이며, 이는 사용자 지정 인증서로 연결됩니다.

HTTPS 요청을 할 때 어떤 일이 발생합니까? 간단한 Ruby 프로그램을 보겠습니다:

```ruby
#!/opt/gitlab/embedded/bin/ruby
require 'openssl'
require 'net/http'

Net::HTTP.get(URI('https://www.google.com'))
```

뒤에서 어떤 일이 발생하는지 설명합니다:

1. `require 'openssl'` 라인은 인터프리터가 `/opt/gitlab/embedded/lib/ruby/2.3.0/x86_64-linux/openssl.so`를 로드하게 합니다.
1. `Net::HTTP` 호출은 `/opt/gitlab/embedded/ssl/certs/cacert.pem`의 기본 인증서 번들을 읽으려고 시도합니다.
1. SSL 협상이 발생합니다.
1. 서버가 SSL 인증서를 보냅니다.
1. 전송된 인증서가 번들에 포함되면 SSL이 성공적으로 완료됩니다.
1. 그렇지 않으면 OpenSSL은 미리 정의된 인증서 디렉터리 내에서 지문과 일치하는 파일을 검색하여 다른 인증서의 유효성을 검사할 수 있습니다. 예를 들어 인증서의 지문이 `7f279c95`인 경우 OpenSSL은 `/opt/gitlab/embedded/ssl/certs/7f279c95.0`을 읽으려고 시도합니다.

OpenSSL 라이브러리는 `SSL_CERT_FILE` 및 `SSL_CERT_DIR` 환경 변수의 정의를 지원합니다. 전자는 로드할 기본 인증서 번들을 정의하고 후자는 더 많은 인증서를 검색할 디렉터리를 정의합니다. `trusted-certs` 디렉터리에 인증서를 추가한 경우에는 이러한 변수가 필요하지 않습니다. 그러나 어떤 이유로든 설정해야 하는 경우 [환경 변수로 정의](../environment-variables.md)할 수 있습니다. 예를 들어:

```ruby
gitlab_rails['env'] = {"SSL_CERT_FILE" => "/usr/lib/ssl/private/customcacert.pem"}
```

## 문제 해결 {#troubleshooting}

[SSL 문제 해결 가이드](ssl_troubleshooting.md)를 참고하세요.
