---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# DNS settings

While it is possible to run a GitLab instance using only IP addresses, it can be beneficial to use DNS for interacting with a GitLab instance from remote nodes. Depending on the features you want to take advantage of, multiple DNS entries may be necessary. Any of these DNS entries should be of type A, AAAA, or CNAME. This depends on the underlying architecture of the instance you are using.

If you don't want to take advantage of the [Let's Encrypt integration](ssl.md#lets-encrypt-integration),
none of these addresses need to be resolvable over the public internet. Only nodes that
will access the GitLab instance need to be able to resolve the addresses.

Adding these entries to your domain's DNS configuration is entirely dependent on your chosen provider, and out of scope for this document. Consult the documentation from your domain name registrar, hosting provider, or managed DNS provider for the most accurate guidance. Instructions for common DNS registrars include:

- [Godaddy](https://www.godaddy.com/help/create-a-subdomain-4080)
- [Namecheap](https://www.namecheap.com/support/knowledgebase/article.aspx/9776/2237/how-to-create-a-subdomain-for-my-domain)
- [Gandi](https://docs.gandi.net/en/domain_names/faq/dns_records.html)
- [Dreamhost](https://help.dreamhost.com/hc/en-us/articles/214694348-Basic-DNS-records)

## GitLab Settings

Below is a list of attributes for `/etc/gitlab/gitlab.rb` that can take advantage of a corresponding DNS entry.

While it is possible to replace the below DNS entries with a wildcard entry in DNS, you still need to provide your GitLab instance with the individual records, and this will **not** result in the Let's Encrypt integration fetching a wildcard certificate.

### `external_url`

This will be the address that will be used to interact with the main GitLab instance. Cloning over SSH/HTTP/HTTPS will use this address. Accessing the web UI will reference this DNS entry. If you are using a GitLab Runner, it will use this address to talk to the instance.

### `registry_external_url`

If you want to use the [container registry](https://docs.gitlab.com/ee/user/packages/container_registry/index.html), this will be an address that is used to interact with the registry. This can also use the same DNS entry as [external_url](#external_url), on a different port. Can be used by the Let's Encrypt integration.

### `mattermost_external_url`

This is needed if you want to use the [bundled Mattermost](../gitlab-mattermost/README.md) software. Can be used by the Let's Encrypt integration.

### `pages_external_url`

By default, projects that use [GitLab Pages](https://docs.gitlab.com/ee/user/project/pages/index.html) will deploy to a sub-domain of this value.

### Auto DevOps domain

If you are going to be deploying projects via GitLab's Auto DevOps, this domain can be used to deploy software. Can be defined at an instance, or cluster level. See the [specific documentation](https://docs.gitlab.com/ee/topics/autodevops/#auto-devops-base-domain) for more details.

## Troubleshooting

If you are having issues accessing a particular component, or if Let's Encrypt integration is failing, you may have a DNS issue. You can use the [dig](https://en.wikipedia.org/wiki/Dig_(command)) tool to check and verify if DNS is causing you a problem.

### Successful DNS query

```shell
$ dig registry.gitlab.com

; <<>> DiG 9.10.6 <<>> registry.gitlab.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12967
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1452
;; QUESTION SECTION:
;registry.gitlab.com.           IN      A

;; ANSWER SECTION:
registry.gitlab.com.    300     IN      A       35.227.35.254

;; Query time: 56 msec
;; SERVER: 172.16.0.1#53(172.16.0.1)
;; WHEN: Fri Mar 20 14:31:24 CDT 2020
;; MSG SIZE  rcvd: 83
```

At the least, you are looking for the status to be `NOERROR`, and the`ANSWER SECTION` for the actual results.

### Failed DNS query

```shell
$ dig fake.gitlab.com

; <<>> DiG 9.10.6 <<>> fake.gitlab.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 50688
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1452
;; QUESTION SECTION:
;fake.gitlab.com.               IN      A

;; AUTHORITY SECTION:
gitlab.com.             900     IN      SOA     ns-705.awsdns-24.net. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400

;; Query time: 101 msec
;; SERVER: 172.16.0.1#53(172.16.0.1)
;; WHEN: Fri Mar 20 14:51:58 CDT 2020
```

Notice here, that the `status` is `NXDOMAIN`, and there is no `ANSWER SECTION`. The `SERVER` field tells you which DNS server was queried for the answer. By default, this is the primary DNS server used by the station the dig command was run from.
