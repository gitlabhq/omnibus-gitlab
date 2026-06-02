---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SSL 문제 해결
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 페이지에는 GitLab으로 작업할 때 발생할 수 있는 일반적인 SSL 관련 오류 및 시나리오 목록이 포함되어 있습니다. 주요 SSL 설명서에 대한 추가 정보로 제공됩니다:

- [Linux 패키지 설치에 대해 SSL 구성](_index.md).
- [러너의 자체 서명 인증서 또는 사용자 지정 인증 기관](https://docs.gitlab.com/runner/configuration/tls-self-signed/).
- [수동으로 HTTPS 구성](_index.md#configure-https-manually).

## 유용한 OpenSSL 디버깅 명령어 {#useful-openssl-debugging-commands}

때로는 SSL 인증서 체인을 소스에서 직접 보고 더 나은 이해를 얻는 것이 도움이 됩니다. 이러한 명령어는 진단 및 디버깅을 위한 표준 OpenSSL 도구 라이브러리의 일부입니다.

> [!note]
> GitLab에는 모든 GitLab 라이브러리가 연결된 [OpenSSL의 사용자 지정 컴파일 버전](_index.md#details-on-how-gitlab-and-ssl-work)이 포함되어 있습니다. 이 OpenSSL 버전을 사용하여 다음 명령어를 실행하는 것이 중요합니다.

- HTTPS를 통해 호스트에 대한 테스트 연결을 수행합니다. `HOSTNAME`을 GitLab URL(HTTPS 제외)로 바꾸고, `port`을 HTTPS 연결을 제공하는 포트(일반적으로 443)로 바꾸세요:

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port
  ```

  `echo` 명령어는 서버에 null 요청을 보내서 추가 입력을 기다리지 않고 연결을 닫게 합니다. 동일한 명령어를 사용하여 원격 호스트(예: 외부 리포지토리를 호스팅하는 서버)를 테스트할 수 있으며, `HOSTNAME:port`을 원격 호스트의 도메인 및 포트 번호로 바꾸면 됩니다.

  이 명령어의 출력은 인증서 체인, 서버가 제공하는 모든 공개 인증서, 발생한 검증 또는 연결 오류를 보여줍니다. 이를 통해 SSL 설정의 즉각적인 이슈를 빠르게 확인할 수 있습니다.

- `x509`을 사용하여 인증서의 세부 정보를 텍스트 형식으로 봅니다. `/path/to/certificate.crt`을 인증서의 경로로 바꾸세요:

  ```shell
  /opt/gitlab/embedded/bin/openssl x509 -in /path/to/certificate.crt -text -noout
  ```

  예를 들어, GitLab은 Let's Encrypt에서 획득한 인증서를 자동으로 가져와 `/etc/gitlab/ssl/hostname.crt`에 배치합니다. 해당 경로에서 `x509` 명령어를 사용하여 인증서 정보(예: 호스트명, 발급자, 유효 기간 등)를 빠르게 표시할 수 있습니다.

  인증서에 문제가 있으면 [오류가 발생합니다](#custom-certificates-missing-or-skipped).

- 서버에서 인증서를 가져와 디코딩합니다. 이것은 위의 두 명령어를 결합하여 서버의 SSL 인증서를 가져오고 텍스트로 디코딩합니다:

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port | /opt/gitlab/embedded/bin/openssl x509 -text -noout
  ```

## 일반적인 SSL 오류 {#common-ssl-errors}

1. `SSL certificate problem: unable to get local issuer certificate`

   이 오류는 클라이언트가 루트 CA를 가져올 수 없음을 나타냅니다. 이를 수정하려면 [루트 CA를 신뢰](_index.md#install-custom-public-certificates) 하거나 연결하려는 서버의 클라이언트에서 또는 [인증서를 수정](_index.md#configure-https-manually)하여 연결하려는 서버에서 전체 연결된 인증서를 제시할 수 있습니다.

   > [!note]
   > 클라이언트가 연결할 때 SSL 오류를 방지하기 위해 전체 인증서 체인을 사용하는 것이 좋습니다. 전체 인증서 체인 순서는 서버 인증서, 모든 중간 인증서, 루트 CA 순서로 구성되어야 합니다.

1. `unable to verify the first certificate`

   이 오류는 불완전한 인증서 체인이 서버에 의해 제시되고 있음을 나타냅니다. 이 오류를 수정하려면 [서버의 인증서를 전체 연결된 인증서로 바꾸어야](_index.md#configure-https-manually) 합니다. 전체 인증서 체인 순서는 서버 인증서, 모든 중간 인증서, 루트 CA 순서로 구성되어야 합니다.

   > [!note]
   > `/opt/gitlab/embedded/bin/openssl` 유틸리티 대신 시스템 OpenSSL 유틸리티를 실행하는 동안 이 오류가 발생하면 OS 수준에서 CA 인증서를 업데이트하여 이를 수정했는지 확인하세요.

1. `certificate signed by unknown authority`

   이 오류는 클라이언트가 인증서 또는 CA를 신뢰하지 않음을 나타냅니다. 이 오류를 수정하려면 서버에 연결하는 클라이언트가 [인증서 또는 CA를 신뢰](_index.md#install-custom-public-certificates)해야 합니다.

1. `SSL certificate problem: self signed certificate in certificate chain`

   이 오류는 클라이언트가 인증서 또는 CA를 신뢰하지 않음을 나타냅니다. 이 오류를 수정하려면 서버에 연결하는 클라이언트가 [인증서 또는 CA를 신뢰](_index.md#install-custom-public-certificates)해야 합니다.

1. `x509: certificate relies on legacy Common Name field, use SANs instead`

   이 오류는 [SANs](http://wiki.cacert.org/FAQ/subjectAltName)(subjectAltName)이 인증서에서 구성되어야 함을 나타냅니다. 자세한 내용은 [이 이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28841)를 참조하세요.

## 인증서로 인한 재구성 실패 {#reconfigure-fails-due-to-certificates}

```shell
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE. Move it from /opt/gitlab/embedded/ssl/certs to a different location and reconfigure again.
```

`/opt/gitlab/embedded/ssl/certs`을 확인하고 `README.md` 이외의 유효하지 않은 X.509 인증서인 파일을 제거합니다.

> [!note]
> `gitlab-ctl reconfigure`를 실행하면 사용자 지정 공개 인증서의 주체 해시에서 이름을 지정한 심볼릭 링크를 생성하고 `/opt/gitlab/embedded/ssl/certs/`에 배치합니다. `/opt/gitlab/embedded/ssl/certs/`의 끊긴 심볼릭 링크가 자동으로 제거됩니다. `cacert.pem` 및 `README.md` 이외의 파일이 `/opt/gitlab/embedded/ssl/certs/`에 저장되면 `/etc/gitlab/trusted-certs/`로 이동됩니다.

## 사용자 지정 인증서 누락 또는 건너뜀 {#custom-certificates-missing-or-skipped}

`/opt/gitlab/embedded/ssl/certs/`에서 심볼릭 링크가 생성되지 않고 `gitlab-ctl reconfigure`를 실행한 후 "`cert.pem` 건너뜀" 메시지가 표시되면 다음 4가지 이슈 중 하나가 있을 수 있습니다:

1. `/etc/gitlab/trusted-certs/`의 파일이 심볼릭 링크입니다
1. 파일이 유효한 PEM 또는 DER 인코딩 인증서가 아닙니다
1. 인증서에 `TRUSTED` 문자열이 포함되어 있습니다

아래 명령어를 사용하여 인증서의 유효성을 테스트합니다:

```shell
/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
/opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

유효하지 않은 인증서 파일은 다음 출력을 생성합니다:

- ```shell
  unable to load certificate
  140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
  ```

- ```shell
  cannot load certificate
  PEM_read_bio_X509_AUX() failed (SSL: error:0909006C:PEM routines:get_name:no start line:Expecting: TRUSTED CERTIFICATE)
  ```

두 경우 모두에서 인증서가 다음 이외의 항목으로 시작하고 끝나면:

```shell
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
```

GitLab과 호환되지 않습니다. 이를 인증서 구성 요소(서버, 중간, 루트)로 분리하고 호환되는 PEM 형식으로 변환해야 합니다.

인증서 자체를 검사하면 `TRUSTED` 문자열을 찾습니다:

```plaintext
-----BEGIN TRUSTED CERTIFICATE-----
...
-----END TRUSTED CERTIFICATE-----
```

그렇다면 위의 예제처럼 `TRUSTED` 문자열을 제거하고 `gitlab-ctl reconfigure`를 다시 실행해 보세요.

## 사용자 지정 인증서 감지 안 됨 {#custom-certificates-not-detected}

`gitlab-ctl reconfigure`를 실행한 후:

1. `/opt/gitlab/embedded/ssl/certs/`에서 심볼릭 링크가 생성되지 않습니다;
1. 사용자 지정 인증서를 `/etc/gitlab/trusted-certs/`에 배치했고;
1. 건너뛰거나 심볼릭 링크된 사용자 지정 인증서 메시지가 표시되지 않습니다

Linux 패키지 설치가 사용자 지정 인증서가 이미 추가된 것으로 생각하는 이슈가 발생할 수 있습니다.

이를 해결하려면 신뢰할 수 있는 인증서 디렉토리 해시를 삭제합니다:

```shell
rm /var/opt/gitlab/trusted-certs-directory-hash
```

그런 다음 `gitlab-ctl reconfigure`를 다시 실행합니다. 이제 재구성이 사용자 지정 인증서를 감지하고 심볼릭 링크해야 합니다.

## Let's Encrypt 인증서에 알 수 없는 기관이 서명됨 {#lets-encrypt-certificate-signed-by-unknown-authority}

Let's Encrypt 통합의 초기 구현은 전체 인증서 체인이 아닌 인증서만 사용했습니다.

10.5.4부터 전체 인증서 체인이 사용됩니다. 이미 인증서를 사용 중인 설치의 경우 갱신 로직이 인증서가 곧 만료됨을 나타낼 때까지 전환이 발생하지 않습니다. 더 빨리 강제하려면 다음을 실행합니다

```shell
rm /etc/gitlab/ssl/HOSTNAME*
gitlab-ctl reconfigure
```

HOSTNAME은 인증서의 호스트명입니다.

## Let's Encrypt이 재구성에서 실패 {#lets-encrypt-fails-on-reconfigure}

> [!note]
> [Let's Debug](https://letsdebug.net/) 진단 도구를 사용하여 도메인을 테스트할 수 있습니다. Let's Encrypt 인증서를 발급할 수 없는 이유를 파악하는 데 도움이 될 수 있습니다.

재구성할 때 Let's Encrypt가 실패할 수 있는 일반적인 시나리오가 있습니다:

- 서버가 Let's Encrypt 검증 서버에 도달할 수 없거나 그 반대인 경우 Let's Encrypt가 실패할 수 있습니다:

  ```shell
  letsencrypt_certificate[gitlab.domain.com] (letsencrypt::http_authorization line 3) had an error: RuntimeError: acme_certificate[staging]  (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 20) had an error: RuntimeError: [gitlab.domain.com] Validation failed for domain gitlab.domain.com
  ```

  Let's Encrypt로 인해 GitLab 재구성에 이슈가 발생하면 [포트 80과 443이 열려 있고 액세스 가능한지 확인](_index.md#enable-the-lets-encrypt-integration)하세요.

- 도메인의 인증 기관 권한 부여(CAA) 레코드가 Let's Encrypt가 도메인에 대한 인증서를 발급할 수 없습니다. 재구성 출력에서 다음 오류를 찾습니다:

  ```shell
  letsencrypt_certificate[gitlab.domain.net] (letsencrypt::http_authorization line 5) had an error: RuntimeError: acme_certificate[staging]   (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 25) had an error: RuntimeError: ruby_block[create certificate for gitlab.domain.net] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/acme/resources/certificate.rb line 108) had an error: RuntimeError: [gitlab.domain.com] Validation failed, unable to request certificate
  ```

- `gitlab.example.com`과 같은 테스트 도메인을 사용 중이고 인증서가 없으면 위에 표시된 `unable to request certificate` 오류가 표시됩니다. 이 경우 `letsencrypt['enable'] = false`을 `/etc/gitlab/gitlab.rb`에 설정하여 Let's Encrypt를 사용하지 않도록 설정합니다.
- [Let's Encrypt는 속도 제한을 적용](https://letsencrypt.org/docs/rate-limits/)하며, 이는 최상위 도메인에서 적용됩니다. 클라우드 공급자의 호스트명을 `external_url`로 사용 중인 경우, 예를 들어 `*.cloudapp.azure.com`, Let's Encrypt는 `azure.com`에 제한을 적용하여 인증서 생성이 불완전할 수 있습니다.

  이 경우 Let's Encrypt 인증서를 수동으로 갱신해 볼 수 있습니다:

  ```shell
  sudo gitlab-ctl renew-le-certs
  ```

## GitLab에서 내부 CA 인증서 사용 {#using-an-internal-ca-certificate-with-gitlab}

GitLab 인스턴스를 내부 CA 인증서로 구성한 후 다양한 CLI 도구를 사용하여 액세스하지 못할 수 있습니다. 다음과 같은 이슈가 발생할 수 있습니다:

- `curl`이 실패합니다:

  ```shell
  curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: unable to get local issuer certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- [레일스 콘솔](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session)을 사용한 테스트도 실패합니다:

  ```ruby
  uri = URI.parse("https://gitlab.domain.tld")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = 1
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  ...
  Traceback (most recent call last):
        1: from (irb):5
  OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate))
  ```

- 이 GitLab 인스턴스에서 [미러링](https://docs.gitlab.com/user/project/repository/mirror/)을 설정할 때 오류 `SSL certificate problem: unable to get local issuer certificate`이 표시됩니다.
- `openssl`은 인증서 경로를 지정할 때 작동합니다:

  ```shell
  /opt/gitlab/embedded/bin/openssl s_client -CAfile /root/my-cert.crt -connect gitlab.domain.tld:443
  ```

앞서 설명한 이슈가 있으면 인증서를 `/etc/gitlab/trusted-certs`에 추가한 다음 `sudo gitlab-ctl reconfigure`를 실행합니다.

## X.509 키 값 불일치 오류 {#x509-key-values-mismatch-error}

인증서 번들로 인스턴스를 구성한 후 NGINX는 다음 오류 메시지를 표시할 수 있습니다:

`SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch`

이 오류 메시지는 제공한 서버 인증서와 키가 일치하지 않음을 의미합니다. 다음 명령어를 실행하고 출력을 비교하여 이를 확인할 수 있습니다:

```shell
openssl rsa -noout -modulus -in path/to/your/.key | openssl md5
openssl x509 -noout -modulus -in path/to/your/.crt | openssl md5
```

다음은 일치하는 키와 인증서 간의 md5 출력 예제입니다. 일치하는 md5 해시를 주의하세요:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
4f49b61b25225abeb7542b29ae20e98c
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

이는 일치하지 않는 키와 인증서의 반대 출력으로 다른 md5 해시를 표시합니다:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
d418865077299af27707b1d1fa83cd99
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

앞의 예제처럼 두 출력이 다르면 인증서와 키 간에 불일치가 있습니다. SSL 인증서 공급자에 문의하여 추가 지원을 받습니다.

## 오류: `certificate signed by unknown authority` {#error-certificate-signed-by-unknown-authority}

[GitLab에서 내부 CA 인증서 사용](ssl_troubleshooting.md#using-an-internal-ca-certificate-with-gitlab)에 언급된 오류를 받는 것 외에도 CI 파이프라인이 `Pending` 상태에서 중단될 수 있습니다. 러너 로그에서 다음 오류 메시지가 표시될 수 있습니다:

```shell
Dec  6 02:43:17 runner-host01 gitlab-runner[15131]: #033[0;33mWARNING: Checking for jobs... failed
#033[0;m  #033[0;33mrunner#033[0;m=Bfkz1fyb #033[0;33mstatus#033[0;m=couldn't execute POST against
https://gitlab.domain.tld/api/v4/jobs/request: Post https://gitlab.domain.tld/api/v4/jobs/request:
x509: certificate signed by unknown authority
```

[러너의 자체 서명 인증서 또는 사용자 지정 인증 기관](https://docs.gitlab.com/runner/configuration/tls-self-signed/)의 세부 정보를 따릅니다.

## 자체 서명된 SSL 인증서를 사용하는 원격 GitLab 리포지토리 미러링 {#mirroring-a-remote-gitlab-repository-that-uses-a-self-signed-ssl-certificate}

로컬 GitLab 인스턴스를 구성하여 자체 서명된 인증서를 사용하는 원격 GitLab 인스턴스에서 [리포지토리를 미러링](https://docs.gitlab.com/user/project/repository/mirror/)할 때 사용자 인터페이스에서 `SSL certificate problem: self signed certificate` 오류 메시지가 표시될 수 있습니다.

다음을 확인하여 이슈의 원인을 확인할 수 있습니다:

- `curl`이 실패합니다:

  ```shell
  $ curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: self signed certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Rails 콘솔을 사용한 테스트도 실패합니다:

  ```ruby
  uri = URI.parse("https://gitlab.domain.tld")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = 1
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  ...
  Traceback (most recent call last):
        1: from (irb):5
  OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate))
  ```

이 문제를 해결하려면:

- 원격 GitLab 인스턴스에서 자체 서명 인증서를 로컬 GitLab 인스턴스의 `/etc/gitlab/trusted-certs` 디렉토리에 추가한 다음 `sudo gitlab-ctl reconfigure`를 실행하고 [사용자 지정 공개 인증서 설치](_index.md#install-custom-public-certificates) 지침에 따릅니다.
- 로컬 GitLab 인스턴스가 Helm Charts를 사용하여 설치된 경우 [GitLab 인스턴스에 자체 서명 인증서를 추가](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#access-gitlab-with-a-custom-certificate)할 수 있습니다.

자체 서명된 인증서를 사용하는 원격 GitLab 인스턴스에서 리포지토리를 미러링하려고 할 때 다른 오류 메시지가 나타날 수 있습니다:

```shell
2:Fetching remote upstream failed: fatal: unable to access &amp;#39;https://gitlab.domain.tld/root/test-repo/&amp;#39;:
SSL: unable to obtain common name from peer certificate
```

이 경우 문제는 인증서 자체와 관련될 수 있습니다:

1. 자체 서명 인증서에 공통 이름이 누락되지 않았는지 확인합니다. 있으면 유효한 인증서를 다시 생성합니다
1. 인증서를 `/etc/gitlab/trusted-certs`에 추가합니다.
1. `sudo gitlab-ctl reconfigure`을(를) 실행합니다.

## 내부 또는 자체 서명된 인증서로 인해 Git 작업을 수행할 수 없음 {#unable-to-perform-git-operations-due-to-an-internal-or-self-signed-certificate}

GitLab 인스턴스가 자체 서명 인증서를 사용하거나 인증서가 내부 인증 기관(CA)으로 서명된 경우 Git 작업을 수행하려고 할 때 다음 오류가 발생할 수 있습니다:

```shell
$ git clone https://gitlab.domain.tld/group/project.git
Cloning into 'project'...
fatal: unable to access 'https://gitlab.domain.tld/group/project.git/': SSL certificate problem: self signed certificate
```

```shell
$ git clone https://gitlab.domain.tld/group/project.git
Cloning into 'project'...
fatal: unable to access 'https://gitlab.domain.tld/group/project.git/': server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
```

이 문제를 해결하려면:

- 가능하면 모든 Git 작업에 SSH 리모트를 사용합니다. 이는 더 안전하고 사용하기 편리한 것으로 간주됩니다.
- HTTPS 리모트를 사용해야 하는 경우 다음을 시도할 수 있습니다:
  - 자체 서명 인증서 또는 내부 루트 CA 인증서를 로컬 디렉토리(예: `~/.ssl`)에 복사하고 Git이 인증서를 신뢰하도록 구성합니다:

    ```shell
    git config --global http.sslCAInfo ~/.ssl/gitlab.domain.tld.crt
    ```

  - Git 클라이언트에서 SSL 검증을 사용하지 않습니다. 이는 일시적 조치로 보안 위험으로 간주될 수 있습니다.

    ```shell
    git config --global http.sslVerify false
    ```

## SSL_connect 잘못된 버전 번호 {#ssl_connect-wrong-version-number}

구성 오류는 다음을 초래할 수 있습니다:

- `gitlab-rails/exceptions_json.log` 항목 포함:

  ```plaintext
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  ```

- `gitlab-workhorse/current` 포함:

  ```plaintext
  http: server gave HTTP response to HTTPS client
  http: server gave HTTP response to HTTPS client
  ```

- `gitlab-rails/sidekiq.log` 또는 `sidekiq/current` 포함:

  ```plaintext
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  ```

이러한 오류 중 일부는 Excon Ruby gem에서 비롯되며 GitLab이 HTTP만 제공하는 원격 서버에 HTTPS 세션을 시작하도록 구성된 경우에 생성될 수 있습니다.

한 가지 시나리오는 [개체 저장소](https://docs.gitlab.com/administration/object_storage/)를 사용 중이며 HTTPS로 제공되지 않는 경우입니다. GitLab이 잘못 구성되어 TLS 핸드셰이크를 시도하지만 개체 저장소가 일반 HTTP로 응답합니다.

## `schannel: SEC_E_UNTRUSTED_ROOT` {#schannel-sec_e_untrusted_root}

Windows를 사용 중이고 다음 오류가 발생하면:

```plaintext
Fatal: unable to access 'https://gitlab.domain.tld/group/project.git': schannel: SEC_E_UNTRUSTED_ROOT (0x80090325) - The certificate chain was issued by an authority that is not trusted."
```

Git이 OpenSSL을 사용해야 함을 지정해야 합니다:

```shell
git config --system http.sslbackend openssl
```

또는 다음을 실행하여 SSL 검증을 무시할 수 있습니다:

> [!warning]
> [SSL을 무시](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpsslVerify)할 때 이 옵션을 전역 수준에서 비활성화하는 것과 관련된 잠재적 보안 이슈로 인해 주의하여 진행합니다. 이 옵션을 _문제 해결할 때만_ 사용하고 즉시 SSL 검증을 다시 시작합니다.

```shell
git config --global http.sslVerify false
```

## OpenSSL 3으로 업그레이드 {#upgrade-to-openssl-3}

[버전 17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770)부터 GitLab은 OpenSSL 3을 사용합니다. 일부 이전 TLS 프로토콜 및 암호 제품군, 또는 외부 통합을 위한 더 약한 TLS 인증서는 OpenSSL 3 기본값과 호환되지 않을 수 있습니다.

OpenSSL 3으로 업그레이드하면:

- 모든 들어오는 TLS 연결과 나가는 TLS 연결에 TLS 1.2 이상이 필요합니다.
- TLS 인증서는 최소 112비트의 보안을 가져야 합니다. 2048비트보다 짧은 RSA, DSA, DH 키와 224비트보다 짧은 ECC 키는 금지됩니다.

다음 오류 메시지 중 하나가 표시될 수 있습니다:

- TLS 연결이 TLS 1.2보다 이전 프로토콜을 사용할 때 `no protocols available`.
- TLS 인증서가 112비트 미만의 보안을 가질 때 `certificate key too weak`.
- 레거시 암호가 요청될 때 `unsupported cipher algorithm`.

[OpenSSL 3 가이드](openssl_3.md)를 사용하여 외부 통합의 호환성을 식별하고 평가합니다.
