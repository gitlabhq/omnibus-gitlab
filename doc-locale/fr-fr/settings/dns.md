---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres DNS
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le Système de Noms de Domaine (DNS) est le système de nommage utilisé pour associer des adresses IP à des noms de domaine.

Bien que vous puissiez exécuter une instance GitLab en utilisant uniquement son adresse IP, l'utilisation d'un nom de domaine présente les avantages suivants :

- Plus facile à mémoriser et à utiliser.
- Obligatoire pour HTTPS.

  > [!note]
  > Pour tirer parti de l'[intégration Let's Encrypt](ssl/_index.md#enable-the-lets-encrypt-integration) (certificats SSL automatiques), le nom de domaine de votre instance doit être résolvable sur l'internet public.

## Utiliser un bureau d'enregistrement de noms {#use-a-name-registrar}

Pour associer un nom de domaine à l'adresse IP de votre instance, vous devez spécifier un ou plusieurs enregistrements DNS. L'ajout d'un enregistrement DNS à la configuration DNS de votre domaine dépend entièrement de votre fournisseur choisi et n'entre pas dans le cadre de ce document.

En général, le processus est similaire à :

1. Visitez le panneau de contrôle de votre bureau d'enregistrement DNS et ajoutez l'enregistrement DNS. Il doit être de l'un des types suivants :

   - `A`
   - `AAAA`
   - `CNAME`

   Le type dépend de l'architecture sous-jacente de votre instance. Le plus courant est l'enregistrement A.

1. [Testez](#successful-dns-query) que la configuration a été appliquée.
1. Utilisez SSH pour vous connecter au serveur où GitLab est installé.
1. Modifiez le fichier de configuration `(/etc/gitlab/gitlab.rb)` avec vos [paramètres GitLab](#gitlab-settings-that-use-dns) préférés.

Pour en savoir plus sur les enregistrements DNS, consultez la [présentation des enregistrements DNS](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/dns_concepts/).

## Utiliser un service DNS dynamique {#use-a-dynamic-dns-service}

Pour une utilisation hors production, vous pouvez utiliser un service DNS dynamique, tel que [nip.io](https://nip.io/).

Nous ne recommandons pas ces services pour les instances de production ou à longue durée de vie, car ils sont souvent :

- [Non sécurisés](https://github.com/publicsuffix/list/issues/335#issuecomment-261825647)
- Soumis à une [limite de débit](https://letsencrypt.org/docs/rate-limits/) par Let's Encrypt

## Paramètres GitLab utilisant le DNS {#gitlab-settings-that-use-dns}

Les paramètres GitLab suivants correspondent à des entrées DNS.

| Paramètre GitLab            | Description | Configuration |
|---------------------------|-------------|---------------|
| `external_url`            | Cette URL interagit avec l'instance GitLab principale. Elle est utilisée lors du clonage via SSH/HTTP/HTTPS et lors de l'accès à l'interface web. GitLab Runner utilise cette URL pour communiquer avec l'instance. | [Configurer le `external_url`](configuration.md#configure-the-external-url-for-gitlab). |
| `registry_external_url`   | Cette URL est utilisée pour interagir avec le [registre de conteneurs](https://docs.gitlab.com/user/packages/container_registry/). Elle peut être utilisée par l'intégration Let's Encrypt. Cette URL peut également utiliser la même entrée DNS que `external_url` mais sur un port différent. | [Configurer le `registry_external_url`](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-domain-configuration). |
| `pages_external_url`      | Par défaut, les projets qui utilisent [GitLab Pages](https://docs.gitlab.com/user/project/pages/) sont déployés dans un sous-domaine de cette valeur. | [Configurer le `pages_external_url`](https://docs.gitlab.com/administration/pages/#configuration). |
| Domaine Auto DevOps        | Si vous utilisez Auto DevOps pour déployer des projets, ce domaine peut être utilisé pour déployer des logiciels. Il peut être défini au niveau d'une instance ou d'un cluster. Cette configuration s'effectue via l'interface GitLab, et non dans `/etc/gitlab/gitlab.rb`. | [Configurer le domaine Auto DevOps](https://docs.gitlab.com/topics/autodevops/requirements/#auto-devops-base-domain). |

## Dépannage {#troubleshooting}

Si vous rencontrez des problèmes pour accéder à un composant particulier, ou si l'intégration Let's Encrypt échoue, vous avez peut-être un problème DNS. Vous pouvez utiliser l'outil [dig](https://en.wikipedia.org/wiki/Dig_(command)) pour déterminer si le DNS est à l'origine du problème.

### Requête DNS réussie {#successful-dns-query}

Cet exemple utilise le [résolveur DNS public Cloudflare](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/) pour s'assurer que la requête est résolvable globalement. Cependant, d'autres résolveurs publics comme le [résolveur DNS public Google](https://developers.google.com/speed/public-dns) sont également disponibles.

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

Assurez-vous que le statut est `NOERROR`, et que la `ANSWER SECTION` contient les résultats réels.

### Requête DNS ayant échoué {#failed-dns-query}

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

Dans cet exemple, le `status` est `NXDOMAIN`, et il n'y a pas de `ANSWER SECTION`. Le champ `SERVER` vous indique quel serveur DNS a été interrogé pour la réponse, dans ce cas le [résolveur DNS public Cloudflare](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/).

### Utiliser une entrée DNS générique {#use-a-wildcard-dns-entry}

Il est possible d'utiliser un DNS générique pour les [attributs d'URL](#gitlab-settings-that-use-dns), mais vous devez fournir le nom de domaine complet pour chacun d'eux.

L'intégration Let's Encrypt ne récupère pas de certificat générique. Vous devez le faire [par vous-même](https://certbot.eff.org/faq/#does-let-s-encrypt-issue-wildcard-certificates).
