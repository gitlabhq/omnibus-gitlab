---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# DNS settings **(FREE SELF)**

The Domain Name System (DNS) is the naming system used to match IP addresses
with domain names.

Although you can run a GitLab instance using only its IP address, using a
domain name is:

- Easier to remember and use.
- Required for HTTPS.

  NOTE:
  To take advantage of the [Let's Encrypt integration](ssl.md#enable-the-lets-encrypt-integration) (automatic SSL certificates),
  your instance's domain name must be resolvable over the public internet.

## Use a name registrar

To associate a domain name with your instance's IP address, you must specify
one or more DNS records.
Adding a DNS record to your domain's DNS configuration is entirely dependent
on your chosen provider, and out of scope for this document.

Generally, the process is similar to:

1. Visit the control panel of your DNS registrar and add the DNS record.
   It should be one of type:

   - `A`
   - `AAAA`
   - `CNAME`

   The type depends on the underlying architecture of your instance. The most
   common one is the A record.

1. [Test](#successful-dns-query) that the configuration was applied.
1. Use SSH to connect to the server where GitLab is installed.
1. Edit the configuration file `(/etc/gitlab/gitlab.rb)` with your preferred [GitLab settings](#gitlab-settings-that-use-dns).

To learn more about the DNS records, see the
[DNS records overview](https://docs.gitlab.com/ee/user/project/pages/custom_domains_ssl_tls_certification/dns_concepts.html).

## Use a dynamic DNS service

For non-production use, you can use a dynamic DNS service, such as [nip.io](https://nip.io).

We do not recommend these for any production or long-lived instances, as they are often:

- [Insecure](https://github.com/publicsuffix/list/issues/335#issuecomment-261825647)
- [Rate-limited](https://letsencrypt.org/docs/rate-limits/) by Let's Encrypt

## GitLab settings that use DNS

The following GitLab settings correspond to DNS entries.

| GitLab setting | Description | Configuration |
| -------------- | ----------- | ------------- |
| `external_url` | This URL interacts with the main GitLab instance. It's used when cloning over SSH/HTTP/HTTPS and when accessing the web UI. GitLab Runner uses this URL to communicate with the instance. | [Configure the `external_url`](configuration.md#configure-the-external-url-for-gitlab). |
| `registry_external_url` | This URL is used to interact with the [Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/). It can be used by the Let's Encrypt integration. This URL can also use the same DNS entry as `external_url` but on a different port. | [Configure the `registry_external_url`](https://docs.gitlab.com/ee/administration/packages/container_registry.html#container-registry-domain-configuration). |
| `mattermost_external_url` | This URL is used for the [bundled Mattermost](https://docs.gitlab.com/ee/integration/mattermost/) software. It can be used by the Let's Encrypt integration. | [Configure the `mattermost_external_url`](https://docs.gitlab.com/ee/integration/mattermost/#getting-started). |
| `pages_external_url` | By default, projects that use [GitLab Pages](https://docs.gitlab.com/ee/user/project/pages/) deploy to a sub-domain of this value. | [Configure the `pages_external_url`](https://docs.gitlab.com/ee/administration/pages/#configuration).
| Auto DevOps domain | If you use Auto DevOps to deploy projects, this domain can be used to deploy software. It can be defined at an instance, or cluster level. This is configured using the GitLab UI, and not in `/etc/gitlab/gitlab.rb`. | [Configure the Auto DevOps domain](https://docs.gitlab.com/ee/topics/autodevops/requirements.html#auto-devops-base-domain). |

## Troubleshooting

If you have issues accessing a particular component, or if the Let's
Encrypt integration is failing, you might have a DNS issue. You can use the
[dig](https://en.wikipedia.org/wiki/Dig_(command)) tool to determine if
DNS is causing a problem.

### Successful DNS query

This example uses the [Public Cloudflare DNS resolver](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/) to ensure that the query is globally resolvable. However, other public resolvers like the [Google Public DNS resolver](https://developers.google.com/speed/public-dns) are also available.

```shell
$ dig registry.gitlab.com @1.1.1.1

; <<>> DiG 9.16.1-Ubuntu <<>> registry.gitlab.com @1.1.1.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4128
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;registry.gitlab.com.   IN  A

;; ANSWER SECTION:
registry.gitlab.com.  37  IN  A  104.18.27.123
registry.gitlab.com.  37  IN  A  104.18.26.123

;; Query time: 4 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Wed Jul 06 10:03:59 CEST 2022
;; MSG SIZE  rcvd: 80

```

Make sure that the status is `NOERROR`, and that the `ANSWER SECTION` has the actual results.

### Failed DNS query

```shell
$ dig fake.gitlab.com @1.1.1.1

; <<>> DiG 9.16.1-Ubuntu <<>> fake.gitlab.com @1.1.1.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 1502
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;fake.gitlab.com.    IN A

;; AUTHORITY SECTION:
gitlab.com.   3600 IN SOA diva.ns.cloudflare.com. dns.cloudflare.com. 2282080190 10000 2400 604800 3600

;; Query time: 8 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Wed Jul 06 10:06:53 CEST 2022
;; MSG SIZE  rcvd: 103
```

In this example, the `status` is `NXDOMAIN`, and there is no `ANSWER SECTION`. The `SERVER` field tells you which DNS server was queried for the answer, in this case the [Public Cloudflare DNS resolver](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/).

### Use a wildcard DNS entry

It is possible use a wildcard DNS for the [URL attributes](#gitlab-settings-that-use-dns),
but you must provide the full domain name for each one.

The Let's Encrypt integration does not fetch a wildcard certificate. You must do this
[on your own](https://certbot.eff.org/faq/#does-let-s-encrypt-issue-wildcard-certificates).
