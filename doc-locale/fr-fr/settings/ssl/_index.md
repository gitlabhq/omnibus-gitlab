---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer SSL pour une installation avec le package Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le package Linux prend en charge plusieurs cas d'utilisation courants pour la configuration SSL.

Par défaut, HTTPS n'est pas activé. Pour activer HTTPS, vous pouvez :

- Utiliser Let's Encrypt pour un HTTPS gratuit et automatisé.
- Configurer manuellement HTTPS avec vos propres certificats.

> [!note]
> Si vous utilisez un proxy, un équilibreur de charge ou un autre dispositif externe pour terminer SSL pour le nom d'hôte GitLab, consultez [Terminaison SSL externe, proxy et équilibreur de charge](#configure-a-reverse-proxy-or-load-balancer-ssl-termination).

Le tableau suivant indique quelle méthode chaque service GitLab prend en charge.

| Service                | SSL manuel                                                                                                                   | Intégration Let's Encrypt |
|------------------------|------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| Domaine de l'instance GitLab | [Oui](#configure-https-manually)                                                                                             | [Oui](#enable-the-lets-encrypt-integration) |
| Registre de conteneurs     | [Oui](https://docs.gitlab.com/administration/packages/container_registry/#configure-container-registry-under-its-own-domain) | [Oui](#enable-the-lets-encrypt-integration) |
| GitLab Pages           | [Oui](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support)                                       | [Oui](#enable-the-lets-encrypt-integration)                        |

## Mise à niveau vers OpenSSL 3 {#openssl-3-upgrade}

À partir de la [version 17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770), GitLab utilise OpenSSL 3. Certains anciens protocoles TLS et suites de chiffrement, ou des certificats TLS plus faibles pour les intégrations externes, peuvent être incompatibles avec les paramètres par défaut d'OpenSSL 3.

Avant de mettre à niveau vers GitLab 17.7, utilisez le [guide OpenSSL 3](openssl_3.md) pour identifier et évaluer la compatibilité de vos intégrations externes.

Après la mise à niveau vers GitLab 17.7, vous pouvez vérifier que GitLab utilise OpenSSL 3 avec la commande suivante :

```shell
/opt/gitlab/embedded/bin/openssl version
```

## Activer l'intégration Let's Encrypt {#enable-the-lets-encrypt-integration}

[Let's Encrypt](https://letsencrypt.org) est activé par défaut si `external_url` est défini avec le protocole HTTPS et qu'aucun autre certificat n'est configuré.

Prérequis :

- Les ports `80` et `443` doivent être accessibles aux serveurs Let's Encrypt publics qui effectuent les vérifications de validation. La validation [ne fonctionne pas avec les ports non standard](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3580). Si l'environnement est privé ou isolé (air-gapped), certbot (l'outil utilisé par Let's Encrypt) fournit une [méthode manuelle](https://eff-certbot.readthedocs.io/en/stable/using.html#manual) pour installer un certificat Let's Encrypt.

Pour activer Let's Encrypt :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ou modifiez les entrées suivantes :

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

   - Les certificats expirent tous les 90 jours. Les adresses e-mail que vous spécifiez pour `contact_emails` reçoivent une alerte lorsque la date d'expiration approche.
   - L'instance GitLab est le nom de domaine principal sur le certificat. Les services supplémentaires tels que le registre de conteneurs sont ajoutés comme noms de domaine alternatifs sur le même certificat. Dans l'exemple ci-dessus, le domaine principal est `gitlab.example.com` et le domaine du registre de conteneurs est `registry.example.com`. Vous n'avez pas besoin de configurer des certificats génériques (wildcard).

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Si Let's Encrypt échoue à émettre un certificat, consultez la [section de dépannage](ssl_troubleshooting.md#lets-encrypt-fails-on-reconfigure) pour obtenir des solutions potentielles.

### Renouveler les certificats automatiquement {#renew-the-certificates-automatically}

Les installations par défaut planifient les renouvellements après minuit, le 4e jour de chaque mois. La minute est déterminée par la valeur dans `external_url` afin de distribuer la charge sur les serveurs Let's Encrypt en amont.

Pour définir explicitement les horaires de renouvellement :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Renew every 7th day of the month at 12:30
   letsencrypt['auto_renew_hour'] = "12"
   letsencrypt['auto_renew_minute'] = "30"
   letsencrypt['auto_renew_day_of_month'] = "*/7"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Le certificat n'est renouvelé que s'il expire dans 30 jours. Par exemple, si vous le configurez pour le renouveler le 1er de chaque mois à 00:00 et que le certificat expire le 31, le certificat expirera avant d'être renouvelé.

Les renouvellements automatiques sont gérés avec [go-crond](https://github.com/webdevops/go-crond). Si souhaité, vous pouvez passer des [arguments CLI](https://github.com/webdevops/go-crond#usage) à go-crond en modifiant le fichier `/etc/gitlab/gitlab.rb` :

```ruby
crond['flags'] = {
  'log.json' = true,
  'server.bind' = ':8040'
}
```

Pour désactiver le renouvellement automatique :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   letsencrypt['auto_renew'] = false
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Renouveler les certificats manuellement {#renew-the-certificates-manually}

Renouvelez les certificats Let's Encrypt manuellement en utilisant l'une des commandes suivantes :

```shell
sudo gitlab-ctl reconfigure
```

```shell
sudo gitlab-ctl renew-le-certs
```

Les commandes précédentes ne génèrent un renouvellement que si le certificat est proche de l'expiration. Si vous rencontrez une erreur lors du renouvellement, [tenez compte des limites de débit en amont](https://letsencrypt.org/docs/rate-limits/).

### Utiliser un serveur ACME autre que Let's Encrypt {#use-an-acme-server-other-than-lets-encrypt}

Vous pouvez utiliser un serveur ACME autre que Let's Encrypt et configurer GitLab pour l'utiliser afin d'obtenir un certificat. Certains services qui fournissent leur propre serveur ACME sont :

- [ZeroSSL](https://zerossl.com/documentation/acme/)
- [Buypass](https://www.buypass.com/products/tls-ssl-certificates/go-ssl)
- [SSL.com](https://www.ssl.com/guide/ssl-tls-certificate-issuance-and-revocation-with-acme/)
- [`step-ca`](https://smallstep.com/docs/step-ca/index.html)

Pour configurer GitLab afin d'utiliser un serveur ACME personnalisé :

1. Modifiez `/etc/gitlab/gitlab.rb` et définissez les points de terminaison ACME :

   ```ruby
   external_url 'https://example.com'
   letsencrypt['acme_staging_endpoint'] = 'https://ca.internal/acme/acme/directory'
   letsencrypt['acme_production_endpoint'] = 'https://ca.internal/acme/acme/directory'
   ```

   Si le serveur ACME personnalisé le fournit, utilisez également un point de terminaison de préproduction (staging). La vérification du point de terminaison de préproduction en premier garantit que la configuration ACME est correcte avant de soumettre la demande en production ACME. Faites-le pour éviter les limites de débit ACME pendant que vous travaillez sur votre configuration.

   Les valeurs par défaut sont :

   ```plaintext
   https://acme-staging-v02.api.letsencrypt.org/directory
   https://acme-v02.api.letsencrypt.org/directory
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Ajouter des domaines alternatifs au certificat {#add-alternative-domains-to-the-certificate}

Par défaut, GitLab définit le Nom commun (CN) et le Nom alternatif du sujet (SAN) du certificat sur le nom d'hôte spécifié dans `external_url`.

Vous pouvez ajouter des domaines alternatifs supplémentaires (ou des noms alternatifs du sujet) au certificat Let's Encrypt. Cela peut être utile si vous souhaitez utiliser le [NGINX intégré](../nginx.md) comme [proxy inverse pour d'autres applications backend](../nginx.md#insert-custom-settings-into-the-nginx-configuration).

Les enregistrements DNS des domaines alternatifs doivent pointer vers l'instance GitLab. Le nom d'hôte `external_url` doit être inclus dans la liste des noms alternatifs du sujet.

Pour ajouter des domaines alternatifs à votre certificat Let's Encrypt :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les domaines alternatifs :

   ```ruby
   # Separate multiple domains with commas
   letsencrypt['alt_names'] = ['gitlab.example.com', 'another-application.example.com']
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Les certificats Let's Encrypt générés pour l'application GitLab principale incluront les domaines alternatifs spécifiés. Les fichiers générés se trouvent à :

- `/etc/gitlab/ssl/gitlab.example.com.key` pour la clé.
- `/etc/gitlab/ssl/gitlab.example.com.crt` pour le certificat.

## Configurer HTTPS manuellement {#configure-https-manually}

> [!warning]
> La configuration NGINX indique aux navigateurs et aux clients de communiquer uniquement avec votre instance GitLab via une connexion sécurisée pendant les 365 prochains jours en utilisant [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security). Consultez [Configurer le HTTP Strict Transport Security](#configure-the-http-strict-transport-security-hsts) pour plus d'options de configuration. Si vous activez HTTPS, vous devez fournir une connexion sécurisée à votre instance pendant au moins les 24 prochains mois.

Pour activer HTTPS :

1. Modifiez `/etc/gitlab/gitlab.rb` :
   1. Définissez `external_url` sur votre domaine. Notez le `https` dans l'URL :

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   1. Désactivez l'intégration Let's Encrypt :

      ```ruby
      letsencrypt['enable'] = false
      ```

      GitLab tente de renouveler tout certificat Let's Encrypt à chaque reconfiguration. Si vous prévoyez d'utiliser votre propre certificat créé manuellement, vous devez désactiver l'intégration Let's Encrypt, sinon le certificat pourrait être écrasé en raison du renouvellement automatique.

1. Créez le répertoire `/etc/gitlab/ssl` et copiez-y votre clé et votre certificat :

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp gitlab.example.com.key gitlab.example.com.crt /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/gitlab.example.com.crt
   sudo chmod 600 /etc/gitlab/ssl/gitlab.example.com.key
   ```

   Dans l'exemple, le nom d'hôte est `gitlab.example.com`, donc l'installation du package Linux recherche des fichiers de clé privée et de certificat public appelés `/etc/gitlab/ssl/gitlab.example.com.key` et `/etc/gitlab/ssl/gitlab.example.com.crt`, respectivement. Si vous le souhaitez, vous pouvez [utiliser un emplacement et des noms de certificats différents](#change-the-default-ssl-certificate-location).

   Vous devez utiliser la chaîne de certificats complète, dans le bon ordre, pour éviter les erreurs SSL lors de la connexion des clients : d'abord le certificat du serveur, puis tous les certificats intermédiaires, et enfin l'autorité de certification racine.

1. Facultatif. Si le fichier `certificate.key` est protégé par un mot de passe, NGINX ne demande pas le mot de passe lorsque vous reconfigurez GitLab. Dans ce cas, l'installation du package Linux échoue silencieusement sans message d'erreur.

   Pour spécifier le mot de passe pour le fichier de clé, stockez le mot de passe dans un fichier texte (par exemple, `/etc/gitlab/ssl/key_file_password.txt`) et ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['ssl_password_file'] = '/etc/gitlab/ssl/key_file_password.txt'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Facultatif. Si vous utilisez un pare-feu, vous devrez peut-être ouvrir le port 443 pour autoriser le trafic HTTPS entrant :

   ```shell
   # UFW example (Debian, Ubuntu)
   sudo ufw allow https

   # lokkit example (RedHat, CentOS 6)
   sudo lokkit -s https

   # firewall-cmd (RedHat, Centos 7)
   sudo firewall-cmd --permanent --add-service=https
   sudo systemctl reload firewalld
   ```

Si vous mettez à jour des certificats existants, suivez un [processus différent](#update-the-ssl-certificates).

### Rediriger les requêtes `HTTP` vers `HTTPS` {#redirect-http-requests-to-https}

Par défaut, lorsque vous spécifiez une `external_url` commençant par `https`, NGINX n'écoute plus le trafic HTTP non chiffré sur le port 80. Pour rediriger tout le trafic HTTP vers HTTPS :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['redirect_http_to_https'] = true
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Ce comportement est activé par défaut lors de l'utilisation de l'[intégration Let's Encrypt](#enable-the-lets-encrypt-integration).

### Modifier le port HTTPS par défaut {#change-the-default-https-port}

Si vous avez besoin d'utiliser un port HTTPS autre que le port par défaut (443), spécifiez-le dans `external_url` :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   external_url "https://gitlab.example.com:2443"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Modifier l'emplacement du certificat SSL par défaut {#change-the-default-ssl-certificate-location}

Si votre nom d'hôte est `gitlab.example.com`, une installation de package Linux recherche par défaut une clé privée appelée `/etc/gitlab/ssl/gitlab.example.com.key` et un certificat public appelé `/etc/gitlab/ssl/gitlab.example.com.crt`.

Pour définir un emplacement différent pour les certificats SSL :

1. Créez un répertoire, accordez-lui les permissions appropriées et placez les fichiers `.crt` et `.key` dans le répertoire :

   ```shell
   sudo mkdir -p /mnt/gitlab/ssl
   sudo chmod 755 /mnt/gitlab/ssl
   sudo cp gitlab.key gitlab.crt /mnt/gitlab/ssl/
   ```

   Vous devez utiliser la chaîne de certificats complète, dans le bon ordre, pour éviter les erreurs SSL lors de la connexion des clients : d'abord le certificat du serveur, puis tous les certificats intermédiaires, et enfin l'autorité de certification racine.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['ssl_certificate'] = "/mnt/gitlab/ssl/gitlab.crt"
   nginx['ssl_certificate_key'] = "/mnt/gitlab/ssl/gitlab.key"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Mettre à jour les certificats SSL {#update-the-ssl-certificates}

Si le contenu de vos certificats SSL a été mis à jour, mais qu'aucune modification de configuration n'a été apportée à `/etc/gitlab/gitlab.rb`, la reconfiguration de GitLab n'affecte pas NGINX. Au lieu de cela, vous devez amener NGINX à [recharger la configuration existante et les nouveaux certificats](http://nginx.org/en/docs/control.html) de manière progressive :

```shell
sudo gitlab-ctl hup nginx
sudo gitlab-ctl hup registry
```

## Configurer la terminaison SSL d'un proxy inverse ou d'un équilibreur de charge {#configure-a-reverse-proxy-or-load-balancer-ssl-termination}

Par défaut, les installations de packages Linux détectent automatiquement si SSL doit être utilisé si `external_url` contient `https://` et configurent NGINX pour la terminaison SSL. Cependant, si vous configurez GitLab pour fonctionner derrière un proxy inverse ou un équilibreur de charge externe, certains environnements peuvent vouloir terminer SSL en dehors de l'application GitLab.

Pour empêcher le NGINX intégré de gérer la terminaison SSL :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['listen_port'] = 80
   nginx['listen_https'] = false
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

L'équilibreur de charge externe peut avoir besoin d'accéder à un point de terminaison GitLab qui renvoie un code de statut `200` (pour les installations nécessitant une connexion, la page racine renvoie une redirection `302` vers la page de connexion). Dans ce cas, il est recommandé d'utiliser un [point de terminaison de vérification de l'état](https://docs.gitlab.com/administration/monitoring/health_check/).

Les autres composants intégrés, comme le registre de conteneurs ou GitLab Pages, utilisent une stratégie similaire pour le SSL via proxy. Définissez le `*_external_url` du composant concerné avec `https://` et préfixez la configuration `nginx[...]` avec le nom du composant. Par exemple, la configuration du registre de conteneurs GitLab est préfixée par `registry_` :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry_external_url 'https://registry.example.com'

   registry_nginx['listen_port'] = 80
   registry_nginx['listen_https'] = false
   ```

   Le même format peut être utilisé pour Pages (préfixe `pages_`).

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Facultatif. Vous devrez peut-être configurer votre proxy inverse ou votre équilibreur de charge pour transmettre certains en-têtes (par exemple `Host`, `X-Forwarded-Ssl`, `X-Forwarded-For`, `X-Forwarded-Port`) à GitLab. Si vous oubliez cette étape, vous pourriez voir des redirections incorrectes ou des erreurs, comme « 422 Unprocessable Entity » ou « Can't verify CSRF token authenticity ».

Certains services de fournisseurs cloud, comme AWS Certificate Manager (ACM), ne permettent pas le téléchargement des certificats. Cela les empêche d'être utilisés pour terminer SSL sur l'instance GitLab. Si SSL est souhaité entre un tel service cloud et GitLab, un autre certificat doit être utilisé sur l'instance GitLab.

## Utiliser des chiffrements SSL personnalisés {#use-custom-ssl-ciphers}

Par défaut, le package Linux [utilise des chiffrements SSL](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/0482fb343a4434ba3a2523a7fb576d2bbb2a3f5f/files/gitlab-cookbooks/gitlab/attributes/default.rb#L876) qui sont une combinaison de tests effectués sur <https://gitlab.com> et de diverses bonnes pratiques contribuées par la communauté GitLab.

Pour modifier les chiffrements SSL :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['ssl_ciphers'] = "CIPHER:CIPHER1"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Pour activer la directive `ssl_dhparam` :

1. Générez `dhparams.pem` :

   ```shell
   openssl dhparam -out /etc/gitlab/ssl/dhparams.pem 2048
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparams.pem"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configurer le protocole HTTP/2 {#configure-the-http2-protocol}

Par défaut, lorsque vous spécifiez que votre instance GitLab est accessible via HTTPS, le [protocole HTTP/2](https://www.rfc-editor.org/rfc/rfc7540) est également activé.

Le package Linux définit les chiffrements SSL requis compatibles avec le protocole HTTP/2.

Si vous spécifiez vos propres [chiffrements SSL personnalisés](#use-custom-ssl-ciphers) et qu'un chiffrement figure dans la [liste noire des chiffrements HTTP/2](https://www.rfc-editor.org/rfc/rfc7540#appendix-A), lorsque vous essayez d'accéder à votre instance GitLab, l'erreur `INADEQUATE_SECURITY` s'affiche dans votre navigateur. Dans ce cas, envisagez de supprimer les chiffrements problématiques de la liste des chiffrements. La modification des chiffrements n'est nécessaire que si vous disposez d'une configuration personnalisée très spécifique.

Pour plus d'informations sur les raisons pour lesquelles vous voudriez activer le protocole HTTP/2, consultez le [livre blanc NGINX HTTP/2](https://cdn.awstatic.com/pub/NGINX_HTTP2_White_Paper_v4.pdf).

Si la modification des chiffrements n'est pas envisageable, vous pouvez désactiver la prise en charge HTTP/2 :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['http2_enabled'] = false
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Le paramètre HTTP/2 ne fonctionne que pour l'application GitLab principale et non pour les autres services, comme GitLab Pages et le registre de conteneurs.

## Activer l'authentification client SSL bidirectionnelle {#enable-2-way-ssl-client-authentication}

Pour exiger que les clients web s'authentifient avec un certificat approuvé, vous pouvez activer le SSL bidirectionnel :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['ssl_verify_client'] = "on"
   nginx['ssl_client_certificate'] = "/etc/pki/tls/certs/root-certs.pem"
   ```

1. Facultatif. Vous pouvez configurer la profondeur de vérification dans la chaîne de certificats que NGINX doit effectuer avant de décider que les clients ne disposent pas d'un certificat valide (la valeur par défaut est `1`). Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['ssl_verify_depth'] = "2"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configurer le HTTP Strict Transport Security (HSTS) {#configure-the-http-strict-transport-security-hsts}

> [!note]
> Les paramètres HSTS ne fonctionnent que pour l'application GitLab principale et non pour les autres services, comme GitLab Pages et le registre de conteneurs.

Le HTTP Strict Transport Security (HSTS) est activé par défaut et informe les navigateurs qu'ils ne doivent contacter le site web qu'en utilisant HTTPS. Lorsqu'un navigateur visite une instance GitLab même une seule fois, il se souvient de ne plus tenter de connexions non sécurisées, même lorsque l'utilisateur saisit explicitement une URL HTTP simple (`http://`). Les URL HTTP simples sont automatiquement redirigées par le navigateur vers la variante `https://`.

Par défaut, `max_age` est défini pour deux ans, ce qui correspond à la durée pendant laquelle un navigateur se souvient de se connecter uniquement via HTTPS.

Pour modifier la valeur de l'âge maximal :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['hsts_max_age'] = 63072000
   nginx['hsts_include_subdomains'] = false
   ```

   Définir `max_age` à `0` désactive HSTS.

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Pour plus d'informations sur HSTS et NGINX, consultez <https://blog.nginx.org/blog/http-strict-transport-security-hsts-and-nginx>.

## Installer des certificats publics personnalisés {#install-custom-public-certificates}

Certains environnements se connectent à des ressources externes pour diverses tâches et GitLab permet à ces connexions d'utiliser HTTPS, et prend en charge les connexions avec des certificats auto-signés. GitLab dispose de son propre bundle ca-cert auquel vous pouvez ajouter des certificats en plaçant les certificats personnalisés individuels dans le répertoire `/etc/gitlab/trusted-certs`. Ils sont ensuite ajoutés au bundle. Ils sont ajoutés à l'aide de la commande `openssl rehash`, qui ne fonctionne que sur un [certificat unique](#using-a-custom-certificate-chain).

Le package Linux est livré avec la collection officielle [Mozilla](https://wiki.mozilla.org/CA/Included_Certificates) d'autorités de certification racines approuvées, utilisées pour vérifier l'authenticité des certificats.

> [!note]
> Pour les installations utilisant des certificats auto-signés, le package Linux fournit un moyen de gérer ces certificats. Pour plus de détails techniques sur son fonctionnement, consultez les [détails](#details-on-how-gitlab-and-ssl-work) en bas de cette page.

Pour installer des certificats publics personnalisés :

1. Générez le certificat public encodé **PEM** ou **DER** à partir de votre certificat de clé privée.
1. Copiez uniquement le fichier de certificat public dans le répertoire `/etc/gitlab/trusted-certs`. Si vous disposez d'une installation multi-nœuds, assurez-vous de copier le certificat sur tous les nœuds.
   - Lors de la configuration de GitLab pour utiliser un certificat public personnalisé, par défaut, GitLab s'attend à trouver un certificat nommé d'après votre nom de domaine GitLab avec une extension `.crt`. Par exemple, si l'adresse de votre serveur est `https://gitlab.example.com`, le certificat doit être nommé `gitlab.example.com.crt`.
   - Si GitLab doit se connecter à une ressource externe utilisant un certificat public personnalisé, stockez le certificat dans le répertoire `/etc/gitlab/trusted-certs` avec une extension `.crt`. Vous n'êtes pas obligé de nommer le fichier d'après le nom de domaine de la ressource externe concernée, bien qu'il soit préférable d'utiliser un schéma de nommage cohérent.

   Pour spécifier un chemin et un nom de fichier différents, vous pouvez [modifier l'emplacement du certificat SSL par défaut](#change-the-default-ssl-certificate-location).

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Utilisation d'une chaîne de certificats personnalisée {#using-a-custom-certificate-chain}

En raison d'un [problème connu](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/1425), si vous utilisez une chaîne de certificats personnalisée, les certificats du serveur, intermédiaires et racines **doivent** être placés dans des fichiers séparés dans le répertoire `/etc/gitlab/trusted-certs`.

Cela s'applique dans les deux cas où GitLab lui-même, ou les ressources externes auxquelles GitLab doit se connecter, utilisent une chaîne de certificats personnalisée.

Par exemple, pour GitLab lui-même, vous pouvez utiliser :

- `/etc/gitlab/trusted-certs/example.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_root.crt`

Pour les ressources externes auxquelles GitLab doit se connecter, vous pouvez utiliser :

- `/etc/gitlab/trusted-certs/external-service.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_root.crt`

## Détails sur le fonctionnement de GitLab et SSL {#details-on-how-gitlab-and-ssl-work}

Le package Linux inclut sa propre bibliothèque OpenSSL et lie tous les programmes compilés (par exemple Ruby, PostgreSQL, etc.) à cette bibliothèque. Cette bibliothèque est compilée pour rechercher les certificats dans `/opt/gitlab/embedded/ssl/certs`.

Le package Linux gère les certificats personnalisés en créant des liens symboliques pour tout certificat ajouté à `/etc/gitlab/trusted-certs/` vers `/opt/gitlab/embedded/ssl/certs` à l'aide de l'outil [openssl rehash](https://docs.openssl.org/3.1/man1/openssl-rehash/). Par exemple, supposons que nous ajoutions `customcacert.pem` à `/etc/gitlab/trusted-certs/` :

```shell
$ sudo ls -al /opt/gitlab/embedded/ssl/certs

total 272
drwxr-xr-x 2 root root   4096 Jul 12 04:19 .
drwxr-xr-x 4 root root   4096 Jul  6 04:00 ..
lrwxrwxrwx 1 root root     42 Jul 12 04:19 7f279c95.0 -> /etc/gitlab/trusted-certs/customcacert.pem
-rw-r--r-- 1 root root 263781 Jul  5 17:52 cacert.pem
-rw-r--r-- 1 root root    147 Feb  6 20:48 README
```

Ici, nous voyons que l'empreinte du certificat est `7f279c95`, qui pointe vers le certificat personnalisé.

Que se passe-t-il lorsque nous effectuons une requête HTTPS ? Prenons un programme Ruby simple :

```ruby
#!/opt/gitlab/embedded/bin/ruby
require 'openssl'
require 'net/http'

Net::HTTP.get(URI('https://www.google.com'))
```

Voici ce qui se passe en coulisses :

1. La ligne `require 'openssl'` amène l'interpréteur à charger `/opt/gitlab/embedded/lib/ruby/2.3.0/x86_64-linux/openssl.so`.
1. L'appel `Net::HTTP` tente ensuite de lire le bundle de certificats par défaut dans `/opt/gitlab/embedded/ssl/certs/cacert.pem`.
1. La négociation SSL se produit.
1. Le serveur envoie ses certificats SSL.
1. Si les certificats envoyés sont couverts par le bundle, SSL se termine avec succès.
1. Sinon, OpenSSL peut valider d'autres certificats en recherchant des fichiers correspondant à leurs empreintes dans le répertoire de certificats prédéfini. Par exemple, si un certificat a l'empreinte `7f279c95`, OpenSSL tentera de lire `/opt/gitlab/embedded/ssl/certs/7f279c95.0`.

La bibliothèque OpenSSL prend en charge la définition des variables d'environnement `SSL_CERT_FILE` et `SSL_CERT_DIR`. La première définit le bundle de certificats par défaut à charger, tandis que la seconde définit un répertoire dans lequel rechercher d'autres certificats. Ces variables ne devraient pas être nécessaires si vous avez ajouté des certificats au répertoire `trusted-certs`. Cependant, si pour une raison quelconque vous devez les définir, elles peuvent être [définies comme variables d'environnement](../environment-variables.md). Par exemple :

```ruby
gitlab_rails['env'] = {"SSL_CERT_FILE" => "/usr/lib/ssl/private/customcacert.pem"}
```

## Dépannage {#troubleshooting}

Consultez notre [guide de dépannage SSL](ssl_troubleshooting.md).
