---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DNS 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Domain Name System(DNS)은 IP 주소를 도메인 이름과 일치시키는 데 사용되는 명명 시스템입니다.

IP 주소만 사용하여 GitLab 인스턴스를 실행할 수 있지만 도메인 이름을 사용하는 것이 더 좋습니다:

- 기억하고 사용하기 쉽습니다.
- HTTPS에 필수입니다.

  > [!note]
  > [Let's Encrypt 통합](ssl/_index.md#enable-the-lets-encrypt-integration)의 이점을 활용하려면(자동 SSL 인증서) 인스턴스의 도메인 이름이 공개 인터넷을 통해 확인 가능해야 합니다.

## 이름 레지스트라 사용 {#use-a-name-registrar}

도메인 이름을 인스턴스의 IP 주소와 연결하려면 하나 이상의 DNS 레코드를 지정해야 합니다. 도메인의 DNS 구성에 DNS 레코드를 추가하는 것은 선택한 제공자에 따라 전적으로 다르며 이 문서의 범위를 벗어납니다.

일반적으로 프로세스는 다음과 같습니다:

1. DNS 레지스트라의 제어판을 방문하여 DNS 레코드를 추가합니다. 다음 유형 중 하나여야 합니다:

   - `A`
   - `AAAA`
   - `CNAME`

   유형은 인스턴스의 기본 아키텍처에 따라 다릅니다. 가장 일반적인 것은 A 레코드입니다.

1. [테스트](#successful-dns-query)하여 구성이 적용되었는지 확인합니다.
1. SSH를 사용하여 GitLab이 설치된 서버에 연결합니다.
1. `(/etc/gitlab/gitlab.rb)` 구성 파일을 선호하는 [GitLab 설정](#gitlab-settings-that-use-dns)으로 편집합니다.

DNS 레코드에 대해 자세히 알아보려면 [DNS 레코드 개요](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/dns_concepts/)를 참조하세요.

## 동적 DNS 서비스 사용 {#use-a-dynamic-dns-service}

비프로덕션 용도로 [nip.io](https://nip.io/)와 같은 동적 DNS 서비스를 사용할 수 있습니다.

프로덕션 또는 장기간 실행되는 인스턴스에는 이러한 서비스를 권장하지 않습니다. 이들은 종종:

- [안전하지 않습니다](https://github.com/publicsuffix/list/issues/335#issuecomment-261825647)
- Let's Encrypt에 의해 [속도 제한](https://letsencrypt.org/docs/rate-limits/)됩니다

## DNS를 사용하는 GitLab 설정 {#gitlab-settings-that-use-dns}

다음 GitLab 설정은 DNS 항목에 해당합니다.

| GitLab 설정            | 설명 | 구성 |
|---------------------------|-------------|---------------|
| `external_url`            | 이 URL은 메인 GitLab 인스턴스와 상호 작용합니다. SSH/HTTP/HTTPS를 통해 복제할 때와 웹 UI에 액세스할 때 사용됩니다. 러너는 이 URL을 사용하여 인스턴스와 통신합니다. | [`external_url`을 구성합니다.](configuration.md#configure-the-external-url-for-gitlab) |
| `registry_external_url`   | 이 URL은 [컨테이너 레지스트리](https://docs.gitlab.com/user/packages/container_registry/)와 상호 작용하는 데 사용됩니다. Let's Encrypt 통합에서 사용할 수 있습니다. 이 URL은 `external_url`과 동일한 DNS 항목을 사용할 수 있지만 다른 포트에서 사용합니다. | [`registry_external_url`을 구성합니다.](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-domain-configuration) |
| `pages_external_url`      | 기본적으로 [GitLab Pages](https://docs.gitlab.com/user/project/pages/)를 사용하는 프로젝트는 이 값의 하위 도메인에 배포됩니다. | [`pages_external_url`을 구성합니다.](https://docs.gitlab.com/administration/pages/#configuration) |
| Auto DevOps 도메인        | Auto DevOps를 사용하여 프로젝트를 배포하면 이 도메인을 사용하여 소프트웨어를 배포할 수 있습니다. 인스턴스 또는 클러스터 수준에서 정의할 수 있습니다. 이는 GitLab UI를 사용하여 구성되며 `/etc/gitlab/gitlab.rb`에서는 구성되지 않습니다. | [Auto DevOps 도메인 구성](https://docs.gitlab.com/topics/autodevops/requirements/#auto-devops-base-domain)합니다. |

## 문제 해결 {#troubleshooting}

특정 구성 요소에 액세스하는 데 이슈가 있거나 Let's Encrypt 통합이 실패하는 경우 DNS 이슈가 있을 수 있습니다. [dig](https://en.wikipedia.org/wiki/Dig_(command)) 도구를 사용하여 DNS가 문제를 일으키는지 확인할 수 있습니다.

### DNS 쿼리 성공 {#successful-dns-query}

이 예제는 [공개 Cloudflare DNS 리졸버](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/)를 사용하여 쿼리가 전역적으로 확인 가능한지 확인합니다. 그러나 [Google 공개 DNS 리졸버](https://developers.google.com/speed/public-dns)와 같은 다른 공개 리졸버도 사용할 수 있습니다.

```shell
$ dig registry.gitlab.com @1.1.1.1

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> registry.gitlab.com @1.1.1.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 3934
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;registry.gitlab.com.  IN A

;; ANSWER SECTION:
registry.gitlab.com. 58 IN A 35.227.35.254

;; Query time: 8 msec
;; SERVER: 1.1.1.1#53(1.1.1.1) (UDP)
;; WHEN: Wed Jan 31 11:16:51 CET 2024
;; MSG SIZE  rcvd: 64

```

상태가 `NOERROR`인지 확인하고 `ANSWER SECTION`에 실제 결과가 있는지 확인합니다.

### DNS 쿼리 실패 {#failed-dns-query}

```shell
$ dig fake.gitlab.com @1.1.1.1

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> fake.gitlab.com @1.1.1.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 25693
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;fake.gitlab.com.  IN A

;; AUTHORITY SECTION:
gitlab.com.  1800 IN SOA diva.ns.cloudflare.com. dns.cloudflare.com. 2331688399 10000 2400 604800 1800

;; Query time: 12 msec
;; SERVER: 1.1.1.1#53(1.1.1.1) (UDP)
;; WHEN: Wed Jan 31 11:17:46 CET 2024
;; MSG SIZE  rcvd: 103

```

이 예제에서 `status`은 `NXDOMAIN`이고 `ANSWER SECTION`이 없습니다. `SERVER` 필드는 어떤 DNS 서버가 응답을 쿼리했는지 알려주며, 이 경우 [공개 Cloudflare DNS 리졸버](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/)입니다.

### 와일드카드 DNS 항목 사용 {#use-a-wildcard-dns-entry}

[URL 속성](#gitlab-settings-that-use-dns)에 와일드카드 DNS를 사용할 수 있지만 각각에 대해 전체 도메인 이름을 제공해야 합니다.

Let's Encrypt 통합은 와일드카드 인증서를 가져오지 않습니다. 이는 [직접 수행](https://certbot.eff.org/faq/#does-let-s-encrypt-issue-wildcard-certificates)해야 합니다.
