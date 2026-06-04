---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: NGINX 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 페이지는 GitLab 설치를 위해 NGINX를 구성하는 관리자 및 DevOps 엔지니어를 위한 구성 정보를 제공합니다. 번들로 제공되는 NGINX(Linux 패키지), Helm 차트 또는 사용자 지정 설정에 특정한 성능 및 보안 최적화를 위한 필수 지침을 포함합니다.

## 서비스별 NGINX 설정 {#service-specific-nginx-settings}

다양한 서비스에 대한 NGINX 설정을 구성하려면 `gitlab.rb` 파일을 편집합니다.

> [!warning]
> 잘못되었거나 호환되지 않는 구성으로 인해 서비스를 사용할 수 없게 될 수 있습니다.

`nginx['<setting>']` 키를 사용하여 GitLab Rails 애플리케이션의 설정을 구성합니다. GitLab은 `pages_nginx`과(와) `registry_nginx` 같은 다른 서비스에 유사한 키를 제공합니다. `nginx`의 구성은 이러한 `<service_nginx>` 설정에도 사용 가능하며 GitLab NGINX와 동일한 기본값을 공유합니다.

`gitlab.rb` 파일을 수정할 때 각 서비스에 대해 NGINX 설정을 별도로 구성합니다. `nginx['foo']`를 사용하여 지정된 설정은 서비스별 NGINX 구성(예: `registry_nginx['foo']`)에 복제되지 않습니다. 예를 들어, GitLab 및 Registry에 대한 HTTP를 HTTPS 리디렉션으로 구성하려면 다음 설정을 `gitlab.rb`에 추가합니다:

```ruby
nginx['redirect_http_to_https'] = true
registry_nginx['redirect_http_to_https'] = true
```

## HTTPS 활성화 {#enable-https}

기본적으로 Linux 패키지 설치는 HTTPS를 사용하지 않습니다. `gitlab.example.com`에 대해 HTTPS를 활성화하려면:

- [Let's Encrypt를 사용하여 무료로 자동 HTTPS 사용](ssl/_index.md#enable-the-lets-encrypt-integration)합니다.
- [자신의 인증서로 HTTPS 수동 구성](ssl/_index.md#configure-https-manually)합니다.

프록시, 로드 밸런서 또는 기타 외부 디바이스를 사용하여 GitLab 호스트 이름에 대한 SSL을 종료하는 경우 [외부, 프록시 및 로드 밸런서 SSL 종료](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination)를 참조하세요.

## 기본 프록시 헤더 변경 {#change-the-default-proxy-headers}

기본적으로 `external_url`을(를) 지정하면 Linux 패키지 설치는 대부분의 환경에 적합한 NGINX 프록시 헤더를 설정합니다.

예를 들어, `external_url`에서 `https` 스키마를 지정하면 Linux 패키지 설치는 다음을 설정합니다:

```plaintext
"X-Forwarded-Proto" => "https",
"X-Forwarded-Ssl" => "on"
```

GitLab 인스턴스가 리버스 프록시 뒤와 같은 더 복잡한 설정에 있는 경우 다음과 같은 오류를 방지하려면 프록시 헤더를 조정해야 할 수 있습니다:

- `The change you wanted was rejected`
- `Can't verify CSRF token authenticity Completed 422 Unprocessable`

기본 헤더를 재정의하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['proxy_set_headers'] = {
     "X-Forwarded-Proto" => "http",
     "CUSTOM_HEADER" => "VALUE"
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

NGINX에서 지원하는 모든 헤더를 지정할 수 있습니다.

## GitLab 신뢰할 수 있는 프록시 및 NGINX `real_ip` 모듈 구성 {#configure-gitlab-trusted-proxies-and-nginx-real_ip-module}

기본적으로 NGINX 및 GitLab은 연결된 클라이언트의 IP 주소를 기록합니다.

GitLab이 리버스 프록시 뒤에 있는 경우 프록시의 IP 주소가 클라이언트 주소로 표시되지 않을 수 있습니다.

NGINX를 다른 주소를 사용하도록 구성하려면 리버스 프록시를 `real_ip_trusted_addresses` 목록에 추가합니다:

```ruby
# Each address is added to the NGINX config as 'set_real_ip_from <address>;'
nginx['real_ip_trusted_addresses'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
# Other real_ip config options
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
```

이러한 옵션에 대한 설명은 [NGINX `realip` 모듈 설명서](http://nginx.org/en/docs/http/ngx_http_realip_module.html)를 참조하세요.

기본적으로 Linux 패키지 설치는 `real_ip_trusted_addresses`의 IP 주소를 GitLab 신뢰할 수 있는 프록시로 사용합니다. 신뢰할 수 있는 프록시 구성은 해당 IP 주소에서 로그인한 것으로 사용자가 나열되는 것을 방지합니다.

파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

## PROXY 프로토콜 구성 {#configure-the-proxy-protocol}

GitLab 앞에서 HAProxy와 같은 프록시를 [PROXY 프로토콜](https://www.haproxy.org/download/3.1/doc/proxy-protocol.txt)과 함께 사용하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Enable termination of ProxyProtocol by NGINX
   nginx['proxy_protocol'] = true
   # Configure trusted upstream proxies. Required if `proxy_protocol` is enabled.
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

이 설정을 활성화한 후 NGINX는 이 리스너에서만 PROXY 프로토콜 트래픽을 수락합니다. 모니터링 검사와 같은 다른 환경을 조정합니다.

## 번들되지 않은 웹 서버 사용 {#use-a-non-bundled-web-server}

> [!note]
> GitLab은 번들되지 않은 웹 서버 설정에 대한 정보를 지침 목적으로만 제공합니다. 번들되지 않은 구성 요소 문제 해결은 [지원 범위 외](https://about.gitlab.com/support/statement-of-support/#out-of-scope-for-all-self-managed-and-saas-users)로 간주됩니다. 번들되지 않은 웹 서버를 사용할 때 질문이나 이슈가 있으면 번들되지 않은 웹 서버 설명서를 참조하세요.

기본적으로 Linux 패키지는 번들 NGINX를 사용하여 GitLab을 설치합니다. Linux 패키지 설치는 `gitlab-www` 사용자를 통해 웹 서버 액세스를 허용하며, 이 사용자는 동일한 이름의 그룹에 속합니다. 외부 웹 서버가 GitLab에 액세스하도록 하려면 외부 웹 서버 사용자를 `gitlab-www` 그룹에 추가합니다.

Apache 또는 기존 NGINX 설치와 같은 다른 웹 서버를 사용하려면:

1. 번들 NGINX를 비활성화합니다:

   `/etc/gitlab/gitlab.rb`에서 다음을 설정합니다:

   ```ruby
   nginx['enable'] = false
   ```

1. 번들되지 않은 웹 서버 사용자의 사용자 이름을 설정합니다:

   Linux 패키지 설치에는 외부 웹 서버 사용자에 대한 기본 설정이 없습니다. 구성에서 이를 지정해야 합니다. 예를 들어:

   - Debian/Ubuntu:  기본 사용자는 Apache 및 NGINX 모두에서 `www-data`입니다.
   - RHEL/CentOS: NGINX 사용자는 `nginx`입니다.

   웹 서버 사용자가 생성되도록 계속하기 전에 Apache 또는 NGINX를 설치합니다. 그렇지 않으면 재구성 중에 Linux 패키지 설치가 실패합니다.

   웹 서버 사용자가 `www-data`인 경우 `/etc/gitlab/gitlab.rb`에서 다음을 설정합니다:

   ```ruby
   web_server['external_users'] = ['www-data']
   ```

   이 설정은 배열이므로 `gitlab-www` 그룹에 추가할 여러 사용자를 지정할 수 있습니다.

   `sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.

   SELinux를 사용하고 웹 서버가 제한된 SELinux 프로필 아래에서 실행되는 경우 [SELinux 권한 구성](https://gitlab.com/gitlab-org/gitlab-recipes/-/blob/master/web-server/apache/README.md#selinux-modifications)이 필요할 수 있습니다.

   웹 서버 사용자가 외부 웹 서버에서 사용하는 모든 디렉터리에 대한 올바른 권한을 가지고 있는지 확인합니다. 그렇지 않으면 `failed (XX: Permission denied) while reading upstream` 오류가 발생할 수 있습니다.

1. 번들되지 않은 웹 서버를 신뢰할 수 있는 프록시 목록에 추가합니다:

   Linux 패키지 설치는 일반적으로 신뢰할 수 있는 프록시 목록을 번들 NGINX에 대한 `real_ip` 모듈의 구성으로 기본값으로 설정합니다.

   번들되지 않은 웹 서버의 경우 목록을 직접 구성합니다. 웹 서버가 GitLab과 동일한 머신에 있지 않으면 웹 서버의 IP 주소를 포함합니다. 그렇지 않으면 사용자가 웹 서버의 IP 주소에서 로그인한 것으로 표시됩니다.

   ```ruby
   gitlab_rails['trusted_proxies'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
   ```

1. 선택 사항입니다. Apache를 사용하는 경우 GitLab Workhorse 설정을 지정합니다:

   Apache는 UNIX 소켓에 연결할 수 없으며 TCP 포트에 연결해야 합니다. GitLab Workhorse가 TCP에서 수신하도록 허용하려면(기본적으로 포트 8181) `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_workhorse['listen_network'] = "tcp"
   gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
   ```

   `sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.

1. 올바른 웹 서버 구성을 다운로드합니다:

   [GitLab 리포지토리](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/support/nginx)로 이동하여 필요한 구성을 다운로드합니다. SSL을 사용하거나 사용하지 않고 GitLab을 제공하기 위한 올바른 구성 파일을 선택합니다. 다음을 변경해야 할 수 있습니다:

   - `YOUR_SERVER_FQDN`의 값을 FQDN으로 변경합니다.
   - SSL을 사용하는 경우 SSL 키의 위치입니다.
   - 로그 파일의 위치입니다.

## NGINX 구성 옵션 {#nginx-configuration-options}

GitLab은 특정 요구 사항에 맞게 NGINX 동작을 사용자 지정할 수 있는 다양한 구성 옵션을 제공합니다. 이러한 참조 항목을 사용하여 NGINX 설정을 미세 조정하고 GitLab 성능 및 보안을 최적화합니다.

### NGINX 리스닝 주소 설정 {#set-the-nginx-listen-addresses}

기본적으로 NGINX는 모든 로컬 IPv4 주소에서 들어오는 연결을 수락합니다.

주소 목록을 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Listen on all IPv4 and IPv6 addresses
   nginx['listen_addresses'] = ["0.0.0.0", "[::]"]
   registry_nginx['listen_addresses'] = ['*', '[::]']
   pages_nginx['listen_addresses'] = ['*', '[::]']
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

### NGINX 리스닝 포트 설정 {#set-the-nginx-listen-port}

기본적으로 NGINX는 `external_url`에 지정된 포트에서 수신하거나 표준 포트(HTTP의 경우 80, HTTPS의 경우 443)를 사용합니다. GitLab을 리버스 프록시 뒤에서 실행하는 경우 리스닝 포트를 재정의할 수 있습니다.

리스닝 포트를 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다. 예를 들어 포트 8081을 사용하려면:

   ```ruby
   nginx['listen_port'] = 8081
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

### NGINX 로그의 세부 정보 표시 수준 변경 {#change-the-verbosity-level-of-nginx-logs}

기본적으로 NGINX는 `error` 세부 정보 표시 수준으로 로그합니다.

로그 수준을 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['error_log_level'] = "debug"
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

유효한 로그 수준 값을 보려면 ['error_log' 지시문](https://nginx.org/en/docs/ngx_core_module.html#error_log)을(를) 참조하세요.

### Referrer-Policy 헤더 설정 {#set-the-referrer-policy-header}

기본적으로 GitLab은 모든 응답에서 `Referrer-Policy` 헤더를 `strict-origin-when-cross-origin`로 설정합니다. 이 설정은 클라이언트를 다음과 같이 설정합니다:

- 같은 출처 요청의 경우 전체 URL을 레퍼러로 전송합니다.
- 교차 출처 요청의 경우 원본만 전송합니다.

이 헤더를 변경하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['referrer_policy'] = 'same-origin'
   ```

   이 헤더를 비활성화하고 클라이언트의 기본 설정을 사용하려면:

   ```ruby
   nginx['referrer_policy'] = false
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

> [!warning]
> 이(가)를 `origin` 또는 `no-referrer`으로 설정하면 전체 레퍼러 URL이 필요한 GitLab 기능이 손상됩니다.

자세한 내용은 [Referrer Policy 사양](https://www.w3.org/TR/referrer-policy/)을(를) 참조하세요.

### Cross-Origin-Resource-Policy 헤더 및 Mermaid 다이어그램 {#cross-origin-resource-policy-header-and-mermaid-diagrams}

`Cross-Origin-Resource-Policy` (CORP) 헤더를 `same-site` 또는 `same-origin` 값으로 구성하면 Mermaid 다이어그램이 자동으로 렌더링되지 않습니다.

예를 들어:

```ruby
nginx['custom_gitlab_server_config'] = "add_header Cross-Origin-Resource-Policy same-site;"
```

Mermaid 샌드박스 iframe은 의도적으로 `allow-same-origin` 샌드박스 속성을 생략합니다. 이로 인해 iframe의 원본이 null이 됩니다. CORP이 `same-site` 또는 `same-origin`으로 설정되면 브라우저가 null 원본 리소스 로드를 차단합니다. null은 어느 정책도 만족하지 않기 때문입니다.

Mermaid 다이어그램을 렌더링하도록 허용하려면 `cross-origin`을(를) 사용합니다:

```ruby
nginx['custom_gitlab_server_config'] = "add_header Cross-Origin-Resource-Policy cross-origin;"
```

> [!warning]
> `cross-origin`은(는) `same-site` 또는 `same-origin`보다 덜 제한적입니다. 이 설정을 사용하기 전에 보안 요구 사항을 검토합니다.

### Gzip 압축 비활성화 {#disable-gzip-compression}

기본적으로 GitLab은 10240바이트 이상의 텍스트 데이터에 대해 Gzip 압축을 활성화합니다. Gzip 압축을 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['gzip_enabled'] = false
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

> [!note]
> `gzip` 설정은 주 GitLab 애플리케이션에만 적용되며 다른 서비스에는 적용되지 않습니다.

### 프록시 요청 버퍼링 비활성화 {#disable-proxy-request-buffering}

특정 위치에 대해 요청 버퍼링을 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.
1. NGINX 구성을 정상적으로 다시 로드합니다:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

`hup` 명령에 대한 자세한 내용은 [NGINX 설명서](https://nginx.org/en/docs/control.html)를 참조하세요.

### `robots.txt` 구성 {#configure-robotstxt}

인스턴스에 대해 사용자 지정 [`robots.txt`](https://www.robotstxt.org/robotstxt.html) 파일을 구성하려면:

1. 사용자 지정 `robots.txt` 파일을 만들고 경로를 기록합니다.
1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['custom_gitlab_server_config'] = "\nlocation =/robots.txt { alias /path/to/custom/robots.txt; }\n"
   ```

   `/path/to/custom/robots.txt`을(를) 사용자 지정 `robots.txt` 파일의 실제 경로로 바꿉니다.

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

이 구성은 [사용자 지정 NGINX 설정](#insert-custom-nginx-settings-into-the-gitlab-server-block)을(를) 추가하여 사용자 지정 `robots.txt` 파일을 제공합니다.

### GitLab 서버 블록에 사용자 지정 NGINX 설정 삽입 {#insert-custom-nginx-settings-into-the-gitlab-server-block}

GitLab에 대한 NGINX `server` 블록에 사용자 지정 설정을 추가하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Example: block raw file downloads from a specific repository
   nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

이렇게 하면 정의된 문자열이 `/var/opt/gitlab/nginx/conf/service_conf/gitlab-rails.conf`의 `server` 블록 끝에 삽입됩니다.

> [!warning]
> 사용자 지정 설정은 `gitlab.rb` 파일의 다른 곳에 정의된 설정과 충돌할 수 있습니다.

#### 기본 서버 비활성화 {#disable-the-default-server}

기본적으로 번들 NGINX는 GitLab 서버 블록의 `listen` 지시문에 `default_server`을(를) 포함합니다. 이 구성으로 인해 NGINX는 이 서버 블록을 다른 서버 블록과 일치하지 않는 모든 요청에 대한 기본값으로 사용합니다.

`default_server`을(를) 포함하는 자신의 사용자 지정 서버 블록을 추가해야 하는 경우(예: `nginx['custom_gitlab_server_config']`를 사용할 때) GitLab 구성에서 기본 서버를 비활성화해야 합니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['default_server_enabled'] = false
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

이 방법은 `listen` 지시문에서 `default_server`을(를) 제거하여 자신의 기본 서버 블록을 정의할 수 있도록 합니다.

#### 참고 {#notes}

- 새 위치를 추가하는 경우 다음을 포함해야 할 수 있습니다:

  ```conf
  proxy_cache off;
  proxy_http_version 1.1;
  proxy_pass http://gitlab-workhorse;
  ```

  이러한 항목이 없으면 하위 위치가 404 오류를 반환할 수 있습니다.

- 루트 `/` 위치 또는 `/assets` 위치는 추가할 수 없습니다. 이미 `gitlab-rails.conf`에 있기 때문입니다.

### NGINX 구성에 사용자 지정 설정 삽입 {#insert-custom-settings-into-the-nginx-configuration}

NGINX 구성에 사용자 지정 설정을 추가하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Example: include a directory to scan for additional config files
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/sites-enabled/*.conf;"
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

이렇게 하면 정의된 문자열이 `/var/opt/gitlab/nginx/conf/nginx.conf`의 `http` 블록 끝에 삽입됩니다.

예를 들어 사용자 지정 서버 블록을 만들고 활성화하려면:

1. `/etc/gitlab/nginx/sites-available` 디렉터리에 사용자 지정 서버 블록을 만듭니다.
1. 디렉터리가 없으면 `/etc/gitlab/nginx/sites-enabled` 디렉터리를 만듭니다.
1. 사용자 지정 서버 블록을 활성화하려면 심볼릭 링크를 만듭니다:

   ```shell
   sudo ln -s /etc/gitlab/nginx/sites-available/example.conf /etc/gitlab/nginx/sites-enabled/example.conf
   ```

1. NGINX 구성을 다시 로드합니다:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

   또는 NGINX를 다시 시작할 수 있습니다:

   ```shell
   sudo gitlab-ctl restart nginx
   ```

생성된 Let's Encrypt SSL 인증서에 서버 블록의 도메인을 [대체 이름으로](ssl/_index.md#add-alternative-domains-to-the-certificate) 추가할 수 있습니다.

`/etc/gitlab/` 디렉터리 내의 사용자 지정 NGINX 설정은 업그레이드 중에 `/etc/gitlab/config_backup/`로 백업되며 `sudo gitlab-ctl backup-etc`이(가) 수동으로 실행될 때도 백업됩니다.

### 사용자 지정 오류 페이지 구성 {#configure-custom-error-pages}

기본 GitLab 오류 페이지의 텍스트를 수정하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['custom_error_pages'] = {
    '404' => {
      'title' => 'Example title',
      'header' => 'Example header',
      'message' => 'Example message'
    }
   }
   ```

   이 예제는 기본 404 오류 페이지를 수정합니다. 이 형식을 404 또는 502와 같은 모든 유효한 HTTP 오류 코드에 사용할 수 있습니다.

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

404 오류 페이지의 결과는 다음과 같습니다:

![사용자 지정 404 오류 페이지](img/error_page_example.png)

### 기존 Passenger 및 NGINX 설치 사용 {#use-an-existing-passenger-and-nginx-installation}

기존 Passenger 및 NGINX 설치로 GitLab을 호스팅하면서도 업데이트 및 설치를 위해 Linux 패키지를 계속 사용할 수 있습니다.

NGINX를 비활성화하면 `nginx.conf`에 수동으로 추가하지 않는 한 Linux 패키지 설치에 포함된 다른 서비스에 액세스할 수 없습니다.

#### 구성 {#configuration}

기존 Passenger 및 NGINX 설치로 GitLab을 설정하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Define the external url
   external_url 'http://git.example.com'

   # Disable the built-in NGINX
   nginx['enable'] = false

   # Disable the built-in Puma
   puma['enable'] = false

   # Set the internal API URL
   gitlab_rails['internal_api_url'] = 'http://git.example.com'

   # Define the web server process user (ubuntu/nginx)
   web_server['external_users'] = ['www-data']
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

#### 가상 호스트(서버 블록) 구성 {#configure-the-virtual-host-server-block}

사용자 지정 Passenger/NGINX 설치에서:

1. 다음 내용으로 새 사이트 구성 파일을 만듭니다:

   ```plaintext
   upstream gitlab-workhorse {
    server unix://var/opt/gitlab/gitlab-workhorse/sockets/socket fail_timeout=0;
   }

   server {
    listen *:80;
    server_name git.example.com;
    server_tokens off;
    root /opt/gitlab/embedded/service/gitlab-rails/public;

    client_max_body_size 250m;

    access_log  /var/log/gitlab/nginx/gitlab_access.log;
    error_log   /var/log/gitlab/nginx/gitlab_error.log;

    # Ensure Passenger uses the bundled Ruby version
    passenger_ruby /opt/gitlab/embedded/bin/ruby;

    # Correct the $PATH variable to included packaged executables
    passenger_env_var PATH "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/usr/local/bin:/usr/bin:/bin";

    # Make sure Passenger runs as the correct user and group to
    # prevent permission issues
    passenger_user git;
    passenger_group git;

    # Enable Passenger & keep at least one instance running at all times
    passenger_enabled on;
    passenger_min_instances 1;

    location ~ ^/[\w\.-]+/[\w\.-]+/(info/refs|git-upload-pack|git-receive-pack)$ {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    location ~ ^/[\w\.-]+/[\w\.-]+/repository/archive {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    location ~ ^/api/v3/projects/.*/repository/archive {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ ^/[\w\.-]+/[\w\.-]+/builds/download {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ /ci/api/v1/builds/[0-9]+/artifacts {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ /api/v4/jobs/[0-9]+/artifacts {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }


    # For protocol upgrades from HTTP/1.0 to HTTP/1.1 we need to provide Host header if its missing
    if ($http_host = "") {
    # use one of values defined in server_name
      set $http_host_with_default "git.example.com";
    }

    if ($http_host != "") {
      set $http_host_with_default $http_host;
    }

    location @gitlab-workhorse {

      ## https://github.com/gitlabhq/gitlabhq/issues/694
      ## Some requests take more than 30 seconds.
      proxy_read_timeout      3600;
      proxy_connect_timeout   300;
      proxy_redirect          off;

      # Do not buffer Git HTTP responses
      proxy_buffering off;

      proxy_set_header    Host                $http_host_with_default;
      proxy_set_header    X-Real-IP           $remote_addr;
      proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
      proxy_set_header    X-Forwarded-Proto   $scheme;

      proxy_http_version 1.1;
      proxy_pass http://gitlab-workhorse;

      ## The following settings only work with NGINX 1.7.11 or newer
      #
      ## Pass chunked request bodies to gitlab-workhorse as-is
      # proxy_request_buffering off;
      # proxy_http_version 1.1;
    }

    ## Enable gzip compression as per rails guide:
    ## http://guides.rubyonrails.org/asset_pipeline.html#gzip-compression
    ## WARNING: If you are using relative urls remove the block below
    ## See config/application.rb under "Relative url support" for the list of
    ## other files that need to be changed for relative url support
    location ~ ^/(assets)/ {
      root /opt/gitlab/embedded/service/gitlab-rails/public;
      gzip_static on; # to serve pre-gzipped version
      expires max;
      add_header Cache-Control public;
    }

    error_page 502 /502.html;
   }
   ```

   `git.example.com`을(를) 서버 URL로 바꿉니다.

403 Forbidden 오류가 발생하면 `/etc/nginx/nginx.conf`에서 Passenger가 활성화되어 있는지 확인하세요:

1. 다음 줄의 주석을 제거합니다:

   ```plaintext
   # include /etc/nginx/passenger.conf;
   ```

1. NGINX 구성을 다시 로드합니다:

   ```shell
   sudo service nginx reload
   ```

### NGINX 상태 모니터링 구성 {#configure-nginx-status-monitoring}

기본적으로 GitLab은 NGINX 서버 상태를 모니터링하기 위해 `127.0.0.1:8060/nginx_status`에서 NGINX 헬스체크 끝점을 구성합니다. VTS(Virtual Host Traffic Status) 모듈이 활성화된 경우(기본값) 이 포트는 `127.0.0.1:8060/metrics`에서도 Prometheus 메트릭을 제공합니다.

끝점은 다음 정보를 표시합니다:

```plaintext
Active connections: 1
server accepts handled requests
18 18 36
Reading: 0 Writing: 1 Waiting: 0
```

- 활성 연결:  전체 열린 연결.
- 다음을 보여주는 세 가지 숫자입니다:
  - 모든 수락된 연결.
  - 모든 처리된 연결.
  - 처리된 요청의 총 개수입니다.
- 읽기:  NGINX가 요청 헤더를 읽습니다.
- 쓰기:  NGINX가 요청 본문을 읽고, 요청을 처리하거나, 클라이언트에게 응답을 작성합니다.
- 대기:  연결 유지. 이 번호는 `keepalive_timeout` 지시문에 따라 달라집니다.

#### NGINX 상태 옵션 구성 {#configure-nginx-status-options}

NGINX 상태 옵션을 구성하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   nginx['status'] = {
    "listen_addresses" => ["127.0.0.1"],
    "fqdn" => "dev.example.com",
    "options" => {
      "access_log" => "off", # Disable logs for stats
      "allow" => "127.0.0.1", # Only allow access from localhost
      "deny" => "all" # Deny access to anyone else
    }
   }
   ```

> [!note]
> VTS가 활성화되면 옵션에 `"stub_status" => "on"`을(를) 포함하지 마세요. 이 설정은 모든 끝점에 적용되며 `/metrics`이(가) Prometheus 메트릭 대신 기본 `nginx_status` 출력을 반환하도록 합니다.

   VTS를 비활성화하고 기본 `nginx_status` 메트릭만 사용하려면:

   ```ruby
   nginx['status']['vts_enable'] = false
   ```

   NGINX 상태 끝점을 비활성화하려면:

   ```ruby
   nginx['status'] = {
    'enable' => false
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성하십시오](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations). 변경 사항이 적용됩니다.

#### VTS 모듈을 사용한 고급 메트릭 구성 {#configure-advanced-metrics-with-vts-module}

GitLab은 지연 시간 백분위수를 포함한 추가 성능 메트릭을 제공하는 NGINX VTS(Virtual Host Traffic Status) 모듈을 포함합니다.

히스토그램 버킷을 사용하여 VTS 모듈을 활성화하기 전에 다음 영향을 고려하세요:

- 메모리 사용량이 증가하여 메트릭 데이터를 저장합니다. 영향은 가상 호스트의 수 및 트래픽 볼륨에 따라 확대됩니다.
- 각 요청에서 히스토그램 메트릭을 계산하면 소량의 CPU를 소비합니다.
- Prometheus에서 이러한 메트릭을 수집하는 경우 추가 저장소가 필요합니다.

높은 트래픽 설치의 경우 이러한 메트릭을 활성화한 후 시스템 리소스를 모니터링하여 성능이 허용 범위 내에 유지되는지 확인합니다.

고급 지연 시간 메트릭을 활성화하려면:

1. `/etc/gitlab/gitlab.rb`에 다음 구성을 추가합니다:

   ```ruby
   nginx['custom_gitlab_server_config'] = "vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;"
   ```

   또는 사용자 지정 NGINX 구성 파일을 만듭니다:

   ```shell
   sudo mkdir -p /etc/gitlab/nginx/conf.d/
   sudo vim /etc/gitlab/nginx/conf.d/vts-custom.conf
   ```

1. 히스토그램 버킷 및 필터링을 활성화하려면 다음 설정을 추가합니다:

   ```nginx
   vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;
   vhost_traffic_status_filter_by_host on;
   vhost_traffic_status_filter on;
   vhost_traffic_status_filter_by_set_key $server_name server::*;
   ```

1. GitLab이 사용자 지정 설정을 포함하도록 구성하려면 다음을 `/etc/gitlab/gitlab.rb`에 추가합니다:

   ```ruby
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/conf.d/vts-custom.conf;"
   ```

1. 재구성하고 NGINX를 다시 시작합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart nginx
   ```

이러한 설정을 활성화한 후 Prometheus 쿼리를 사용하여 다양한 지연 시간 메트릭을 모니터링할 수 있습니다:

```plaintext
# Average response time
rate(nginx_vts_server_request_seconds_total[5m]) / rate(nginx_vts_server_requests_total{code=~"2xx|3xx|4xx|5xx"}[5m])

# P90 latency
histogram_quantile(0.90, rate(nginx_vts_server_request_duration_seconds_bucket[5m]))

# P99 latency
histogram_quantile(0.99, rate(nginx_vts_server_request_duration_seconds_bucket[5m]))

# Average upstream response time
rate(nginx_vts_upstream_response_seconds_total[5m]) / rate(nginx_vts_upstream_requests_total{code=~"2xx|3xx|4xx|5xx"}[5m])

# P90 upstream latency
histogram_quantile(0.90, rate(nginx_vts_upstream_response_duration_seconds_bucket[5m]))

# P99 upstream latency
histogram_quantile(0.99, rate(nginx_vts_upstream_response_duration_seconds_bucket[5m]))
```

GitLab Workhorse 관련 메트릭의 경우 다음을 사용할 수 있습니다:

```plaintext
# 90th percentile upstream latency for GitLab Workhorse
histogram_quantile(0.90, rate(nginx_vts_upstream_response_duration_seconds_bucket{upstream="gitlab-workhorse"}[5m]))

# Average upstream response time for GitLab Workhorse
rate(nginx_vts_upstream_response_seconds_total{upstream="gitlab-workhorse"}[5m]) /
rate(nginx_vts_upstream_requests_total{upstream="gitlab-workhorse",code=~"2xx|3xx|4xx|5xx"}[5m])
```

#### 업로드에 대한 사용자 권한 구성 {#configure-user-permissions-for-uploads}

사용자 업로드가 액세스 가능한지 확인하려면 NGINX 사용자(일반적으로 `www-data`)를 `gitlab-www` 그룹에 추가합니다:

```shell
sudo usermod -aG gitlab-www www-data
```

### 템플릿 {#templates}

구성 파일은 [번들 GitLab NGINX 구성](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-rails.conf.erb)과 유사하며 다음과 같은 차이점이 있습니다:

- Puma 대신 Passenger 구성이 사용됩니다.
- HTTPS는 기본적으로 활성화되지 않지만 활성화할 수 있습니다.

NGINX 구성을 변경한 후:

- Debian 기반 시스템의 경우 NGINX를 다시 시작합니다:

  ```shell
  sudo service nginx restart
  ```

- 다른 시스템의 경우 NGINX를 다시 시작하는 올바른 명령에 대해 운영 체제 설명서를 참조하세요.
