---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenSSL 3으로 업그레이드
---

[버전 17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770)부터 GitLab은 OpenSSL 3을 사용합니다. 이 버전의 OpenSSL은 주요 릴리스로서 주목할 만한 결함 및 OpenSSL의 기본 동작 변경이 포함되어 있습니다(자세한 내용은 [OpenSSL 3 마이그레이션 가이드](https://docs.openssl.org/3.0/man7/migration_guide/)를 참조하세요).

외부 통합을 위한 이전 버전의 TLS 및 암호화 모음 중 일부는 이러한 변경 사항과 호환되지 않을 수 있습니다. 따라서 OpenSSL 3을 사용하는 GitLab 버전으로 업그레이드하기 전에 외부 통합의 호환성을 평가하는 것이 중요합니다.

OpenSSL 3으로 업그레이드하면:

- 모든 들어오는 TLS 연결과 나가는 TLS 연결에 TLS 1.2 이상이 필요합니다.
- TLS 인증서는 최소 112비트의 보안을 가져야 합니다. 2048비트보다 짧은 RSA, DSA, DH 키와 224비트보다 짧은 ECC 키는 금지됩니다.

## 운영 체제 업그레이드가 필요 없음 {#no-operating-system-upgrades-needed}

GitLab이 OpenSSL 3을 지원하기 위해 운영 체제를 업그레이드할 필요는 없습니다. Linux 패키지 및 Helm Chart의 경우 GitLab CE와 EE는 자체 OpenSSL 버전을 제공하므로 운영 체제의 OpenSSL 버전을 사용하지 않습니다. 그러나 [FIPS 빌드](https://docs.gitlab.com/development/fips_gitlab/)는 해당 라이브러리가 FIPS 인증을 받기 때문에 운영 체제의 OpenSSL을 사용합니다.

## 외부 통합 식별 {#identifying-external-integrations}

외부 통합은 `gitlab.rb`으로 구성하거나 프로젝트, 그룹 또는 관리자 **설정**의 GitLab 웹 인터페이스를 통해 구성할 수 있습니다.

다음은 사용할 수 있는 통합의 예비 목록입니다:

- 인증 및 권한 부여
  - [LDAP 서버](https://docs.gitlab.com/administration/auth/ldap/)
  - [OmniAuth 공급자](https://docs.gitlab.com/integration/omniauth/), 특히 SAML 또는 Shibboleth와 같은 흔하지 않은 공급자
  - [승인된 애플리케이션](https://docs.gitlab.com/integration/oauth_provider/#view-all-authorized-applications)
- 이메일
  - [수신 이메일](https://docs.gitlab.com/administration/incoming_email/#configuration-examples)
  - [Service Desk](https://docs.gitlab.com/user/project/service_desk/configure/)
  - [SMTP 서버](../smtp.md)
- [프로젝트 통합](https://docs.gitlab.com/user/project/integrations/)
- [외부 이슈 추적기](https://docs.gitlab.com/integration/external-issue-tracker/)
- [웹후크](https://docs.gitlab.com/user/project/integrations/webhooks/)
- [외부 PostgreSQL](https://docs.gitlab.com/administration/postgresql/external/)
- [외부 Redis](https://docs.gitlab.com/administration/redis/replication_and_failover_external/)
- [오브젝트 스토리지](https://docs.gitlab.com/administration/object_storage/)
- [ClickHouse](https://docs.gitlab.com/integration/clickhouse/)
- 모니터링
  - [외부 Prometheus 서버](https://docs.gitlab.com/administration/monitoring/prometheus/#using-an-external-prometheus-server)
  - [Grafana](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/)
  - [원격 Prometheus](../prometheus.md#remote-readwrite)

Linux 패키지와 함께 제공되는 모든 구성 요소는 OpenSSL 3과 호환됩니다. 따라서 GitLab 패키지의 일부가 아니고 "외부"인 서비스만 확인하면 됩니다.

## OpenSSL 3과의 호환성 평가 {#assessing-compatibility-with-openssl-3}

다양한 도구를 사용하여 외부 통합 엔드포인트의 호환성을 확인할 수 있습니다. 사용하는 도구와 관계없이 지원되는 TLS 버전과 암호화 모음을 확인해야 합니다.

### `openssl` 명령줄 도구 {#openssl-command-line-tool}

[`openssl s_client`](https://docs.openssl.org/3.0/man1/openssl-s_client/) 명령줄 도구를 사용하여 TLS 활성화 서버에 연결할 수 있습니다. 특정 TLS 버전 또는 암호화를 적용하기 위해 사용할 수 있는 다양한 옵션이 있습니다.

1. 시스템 `openssl` 클라이언트를 사용하여 OpenSSL 3 명령줄 도구를 사용하고 있는지 버전을 확인하여 확인합니다:

   ```shell
   openssl version
   ```

   시스템 OpenSSL 클라이언트를 사용하여 이 확인을 수행하면 [GitLab과 함께 제공되는 OpenSSL 버전](_index.md#details-on-how-gitlab-and-ssl-work)이 버전 3으로 업그레이드되었을 때 호환성을 보장합니다.

1. 서버가 암호화 및 TLS 버전을 지원하는지 확인하는 다음 예제 셸 스크립트를 사용합니다:

   ```shell
   # Host and port of the server
   SERVER='HOST:PORT'

   # Check supported ciphers for TLS1.2 and TLS1.3
   # See `openssl s_client` manual for other available options.
   for tls_version in tls1_2 tls1_3; do
     echo "Supported ciphers for ${tls_version}:"
     for cipher in $(openssl ciphers -${tls_version} | sed -e 's/:/ /g'); do
       # NOTE: The cipher will be combined with any TLSv1.3 cipher suites that
       # have been configured.
       if openssl s_client -${tls_version} -cipher "${cipher}" -connect ${SERVER} </dev/null >/dev/null 2>&1; then
         printf "\t%s\n" "${cipher}"
       fi
     done
   done
   ```

PostgreSQL 데이터베이스 또는 SMTP 서버에 연결할 때와 같은 경우에는 TLS 연결을 설정하기 위해 `-starttls` 옵션을 제공해야 합니다. 자세한 내용은 [OpenSSL 설명서](https://docs.openssl.org/master/man1/openssl-s_client/#options)를 참조하세요. 예를 들어:

```shell
openssl s_client -connect YOUR_DATABASE_SERVER:5432 -tls1_2 -starttls postgres
```

### Nmap `ssl-enum-ciphers` 스크립트 {#nmap-ssl-enum-ciphers-script}

Nmap의 [`ssl-enum-ciphers` 스크립트](https://nmap.org/nsedoc/scripts/ssl-enum-ciphers.html)는 지원되는 TLS 버전 및 암호화를 식별하고 자세한 출력을 제공합니다.

1. [`nmap` 설치](https://nmap.org/book/install.html)
1. 사용 중인 버전이 OpenSSL 3과 호환되는지 확인합니다:

   ```shell
   nmap --version
   ```

   출력에는 Nmap이 "컴파일된" OpenSSL 버전을 포함한 버전 세부 정보가 표시되어야 합니다.

1. `nmap`를 테스트 중인 사이트에 대해 실행합니다:

   ```shell
   nmap -sV --script ssl-enum-ciphers -p PORT HOST
   ```

   다음과 유사한 출력이 표시되어야 합니다:

   ```plaintext
   PORT    STATE SERVICE  VERSION
   443/tcp open  ssl/http Cloudflare http proxy
   | ssl-enum-ciphers:
   |   TLSv1.2:
   |     ciphers:
   |       TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256-draft (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_128_GCM_SHA256 (rsa 2048) - A
   |       TLS_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
   |       TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_256_GCM_SHA384 (rsa 2048) - A
   |       TLS_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
   |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256 (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_128_CBC_SHA256 (rsa 2048) - A
   |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384 (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_256_CBC_SHA256 (rsa 2048) - A
   |     compressors:
   |       NULL
   |     cipher preference: server
   |   TLSv1.3:
   |     ciphers:
   |       TLS_AKE_WITH_AES_128_GCM_SHA256 (ecdh_x25519) - A
   |       TLS_AKE_WITH_AES_256_GCM_SHA384 (ecdh_x25519) - A
   |       TLS_AKE_WITH_CHACHA20_POLY1305_SHA256 (ecdh_x25519) - A
   |     cipher preference: client
   |_  least strength: A
   |_http-server-header: cloudflare
   ```
