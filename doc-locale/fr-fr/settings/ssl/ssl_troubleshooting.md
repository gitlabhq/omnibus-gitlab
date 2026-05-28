---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage SSL
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette page contient une liste d'erreurs et de scénarios courants liés à SSL que vous pouvez rencontrer lorsque vous travaillez avec GitLab. Elle doit servir de complément à la documentation SSL principale :

- [Configurer SSL pour une installation de package Linux](_index.md).
- [Certificats auto-signés ou autorités de certification personnalisées pour GitLab Runner](https://docs.gitlab.com/runner/configuration/tls-self-signed/).
- [Configurer HTTPS manuellement](_index.md#configure-https-manually).

## Commandes de débogage OpenSSL utiles {#useful-openssl-debugging-commands}

Il est parfois utile d'avoir une meilleure vue de la chaîne de certificats SSL en la consultant directement à la source. Ces commandes font partie de la bibliothèque standard d'outils OpenSSL pour les diagnostics et le débogage.

> [!note]
> GitLab inclut sa propre [version personnalisée compilée d'OpenSSL](_index.md#details-on-how-gitlab-and-ssl-work) contre laquelle toutes les bibliothèques GitLab sont liées. Il est important d'exécuter les commandes suivantes en utilisant cette version d'OpenSSL.

- Effectuez une connexion de test à l'hôte via HTTPS. Remplacez `HOSTNAME` par l'URL de votre GitLab (sans HTTPS), et remplacez `port` par le port qui gère les connexions HTTPS (généralement 443) :

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port
  ```

  La commande `echo` envoie une requête nulle au serveur, ce qui l'oblige à fermer la connexion plutôt qu'à attendre une entrée supplémentaire. Vous pouvez utiliser la même commande pour tester des hôtes distants (par exemple, un serveur hébergeant un dépôt externe), en remplaçant `HOSTNAME:port` par le domaine et le numéro de port de l'hôte distant.

  La sortie de cette commande vous affiche la chaîne de certificats, tous les certificats publics présentés par le serveur, ainsi que les erreurs de validation ou de connexion si elles se produisent. Cela permet de vérifier rapidement tout problème immédiat avec vos paramètres SSL.

- Affichez les détails d'un certificat sous forme de texte en utilisant `x509`. Assurez-vous de remplacer `/path/to/certificate.crt` par le chemin du certificat :

  ```shell
  /opt/gitlab/embedded/bin/openssl x509 -in /path/to/certificate.crt -text -noout
  ```

  Par exemple, GitLab récupère et place automatiquement les certificats obtenus auprès de Let's Encrypt à l'emplacement `/etc/gitlab/ssl/hostname.crt`. Vous pouvez utiliser la commande `x509` avec ce chemin pour afficher rapidement les informations du certificat (par exemple, le nom d'hôte, l'émetteur, la période de validité, etc.).

  En cas de problème avec le certificat, [une erreur se produit](#custom-certificates-missing-or-skipped).

- Récupérez un certificat depuis un serveur et décodez-le. Cette commande combine les deux commandes ci-dessus pour récupérer le certificat SSL du serveur et le décoder en texte :

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port | /opt/gitlab/embedded/bin/openssl x509 -text -noout
  ```

## Erreurs SSL courantes {#common-ssl-errors}

1. `SSL certificate problem: unable to get local issuer certificate`

   Cette erreur indique que le client ne peut pas obtenir le CA racine. Pour résoudre ce problème, vous pouvez soit [faire confiance au CA racine](_index.md#install-custom-public-certificates) du serveur auquel vous essayez de vous connecter sur le client, soit [modifier le certificat](_index.md#configure-https-manually) pour présenter le certificat complet en chaîne sur le serveur auquel vous essayez de vous connecter.

   > [!note]
   > Il est recommandé d'utiliser la chaîne de certificats complète afin d'éviter les erreurs SSL lors de la connexion des clients. L'ordre de la chaîne de certificats complète doit être le suivant : le certificat du serveur en premier, suivi de tous les certificats intermédiaires, et le CA racine en dernier.

1. `unable to verify the first certificate`

   Cette erreur indique qu'une chaîne de certificats incomplète est présentée par le serveur. Pour corriger cette erreur, vous devrez [remplacer le certificat du serveur par le certificat complet en chaîne](_index.md#configure-https-manually). L'ordre de la chaîne de certificats complète doit être le suivant : le certificat du serveur en premier, suivi de tous les certificats intermédiaires, et le CA racine en dernier.

   > [!note]
   > Si vous obtenez cette erreur lors de l'utilisation de l'utilitaire système OpenSSL au lieu de l'utilitaire `/opt/gitlab/embedded/bin/openssl`, assurez-vous de mettre à jour vos certificats CA au niveau du système d'exploitation pour résoudre le problème.

1. `certificate signed by unknown authority`

   Cette erreur indique que le client ne fait pas confiance au certificat ou au CA. Pour corriger cette erreur, le client qui se connecte au serveur devra [faire confiance au certificat ou au CA](_index.md#install-custom-public-certificates).

1. `SSL certificate problem: self signed certificate in certificate chain`

   Cette erreur indique que le client ne fait pas confiance au certificat ou au CA. Pour corriger cette erreur, le client qui se connecte au serveur devra [faire confiance au certificat ou au CA](_index.md#install-custom-public-certificates).

1. `x509: certificate relies on legacy Common Name field, use SANs instead`

   Cette erreur indique que les [SANs](http://wiki.cacert.org/FAQ/subjectAltName) (subjectAltName) doivent être configurés dans le certificat. Pour plus d'informations, consultez [ce ticket](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28841).

## Échec de la reconfiguration en raison de certificats {#reconfigure-fails-due-to-certificates}

```shell
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE. Move it from /opt/gitlab/embedded/ssl/certs to a different location and reconfigure again.
```

Vérifiez `/opt/gitlab/embedded/ssl/certs` et supprimez tout fichier autre que `README.md` qui n'est pas un certificat X.509 valide.

> [!note]
> L'exécution de `gitlab-ctl reconfigure` crée des liens symboliques nommés d'après les hachages de sujet de vos certificats publics personnalisés et les place dans `/opt/gitlab/embedded/ssl/certs/`. Les liens symboliques brisés dans `/opt/gitlab/embedded/ssl/certs/` seront automatiquement supprimés. Les fichiers autres que `cacert.pem` et `README.md` stockés dans `/opt/gitlab/embedded/ssl/certs/` seront déplacés dans `/etc/gitlab/trusted-certs/`.

## Certificats personnalisés manquants ou ignorés {#custom-certificates-missing-or-skipped}

Si aucun lien symbolique n'est créé dans `/opt/gitlab/embedded/ssl/certs/` et que vous voyez le message « Skipping `cert.pem` » après l'exécution de `gitlab-ctl reconfigure`, cela signifie qu'il peut y avoir l'un des quatre problèmes suivants :

1. Le fichier dans `/etc/gitlab/trusted-certs/` est un lien symbolique
1. Le fichier n'est pas un certificat valide encodé en PEM ou en DER
1. Le certificat contient la chaîne `TRUSTED`

Testez la validité du certificat à l'aide des commandes ci-dessous :

```shell
/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
/opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

Les fichiers de certificats non valides produisent les sorties suivantes :

- ```shell
  unable to load certificate
  140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
  ```

- ```shell
  cannot load certificate
  PEM_read_bio_X509_AUX() failed (SSL: error:0909006C:PEM routines:get_name:no start line:Expecting: TRUSTED CERTIFICATE)
  ```

Dans l'un ou l'autre de ces cas, et si vos certificats commencent et se terminent par autre chose que ce qui suit :

```shell
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
```

Ils ne sont pas compatibles avec GitLab. Vous devez les séparer en composants de certificat (serveur, intermédiaire, racine) et les convertir au format PEM compatible.

Si vous inspectez le certificat lui-même, recherchez la chaîne `TRUSTED` :

```plaintext
-----BEGIN TRUSTED CERTIFICATE-----
...
-----END TRUSTED CERTIFICATE-----
```

Si c'est le cas, comme dans l'exemple ci-dessus, essayez de supprimer la chaîne `TRUSTED` et relancez `gitlab-ctl reconfigure`.

## Certificats personnalisés non détectés {#custom-certificates-not-detected}

Si après l'exécution de `gitlab-ctl reconfigure` :

1. aucun lien symbolique n'est créé dans `/opt/gitlab/embedded/ssl/certs/` ;
1. vous avez placé des certificats personnalisés dans `/etc/gitlab/trusted-certs/` ; et
1. vous ne voyez aucun message de certificat personnalisé ignoré ou avec lien symbolique

Vous rencontrez peut-être un problème où une installation de package Linux pense que les certificats personnalisés ont déjà été ajoutés.

Pour résoudre ce problème, supprimez le hachage du répertoire des certificats de confiance :

```shell
rm /var/opt/gitlab/trusted-certs-directory-hash
```

Exécutez ensuite `gitlab-ctl reconfigure` à nouveau. La reconfiguration devrait maintenant détecter et créer des liens symboliques pour vos certificats personnalisés.

## Certificat Let's Encrypt signé par une autorité inconnue {#lets-encrypt-certificate-signed-by-unknown-authority}

L'implémentation initiale de l'intégration Let's Encrypt n'utilisait que le certificat, et non la chaîne de certificats complète.

À partir de la version 10.5.4, la chaîne de certificats complète sera utilisée. Pour les installations qui utilisent déjà un certificat, le basculement n'aura pas lieu tant que la logique de renouvellement n'indique pas que le certificat est proche de l'expiration. Pour forcer le basculement plus tôt, exécutez la commande suivante

```shell
rm /etc/gitlab/ssl/HOSTNAME*
gitlab-ctl reconfigure
```

Où HOSTNAME est le nom d'hôte du certificat.

## Let's Encrypt échoue lors de la reconfiguration {#lets-encrypt-fails-on-reconfigure}

> [!note]
> Vous pouvez tester votre domaine en utilisant l'outil de diagnostic [Let's Debug](https://letsdebug.net/). Il peut vous aider à comprendre pourquoi vous ne pouvez pas émettre un certificat Let's Encrypt.

Lorsque vous reconfigurez, il existe des scénarios courants dans lesquels Let's Encrypt peut échouer :

- Let's Encrypt peut échouer si votre serveur n'est pas en mesure d'atteindre les serveurs de vérification Let's Encrypt ou vice versa :

  ```shell
  letsencrypt_certificate[gitlab.domain.com] (letsencrypt::http_authorization line 3) had an error: RuntimeError: acme_certificate[staging]  (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 20) had an error: RuntimeError: [gitlab.domain.com] Validation failed for domain gitlab.domain.com
  ```

  Si vous rencontrez des problèmes lors de la reconfiguration de GitLab en raison de Let's Encrypt, [assurez-vous que les ports 80 et 443 sont ouverts et accessibles](_index.md#enable-the-lets-encrypt-integration).

- L'enregistrement CAA (Certification Authority Authorization) de votre domaine n'autorise pas Let's Encrypt à émettre un certificat pour votre domaine. Recherchez l'erreur suivante dans la sortie de la reconfiguration :

  ```shell
  letsencrypt_certificate[gitlab.domain.net] (letsencrypt::http_authorization line 5) had an error: RuntimeError: acme_certificate[staging]   (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 25) had an error: RuntimeError: ruby_block[create certificate for gitlab.domain.net] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/acme/resources/certificate.rb line 108) had an error: RuntimeError: [gitlab.domain.com] Validation failed, unable to request certificate
  ```

- Si vous utilisez un domaine de test tel que `gitlab.example.com`, sans certificat, vous verrez l'erreur `unable to request certificate` affichée ci-dessus. Dans ce cas, désactivez Let's Encrypt en définissant `letsencrypt['enable'] = false` dans `/etc/gitlab/gitlab.rb`.
- [Let's Encrypt applique des limites de débit](https://letsencrypt.org/docs/rate-limits/), qui s'appliquent au domaine de premier niveau. Si vous utilisez le nom d'hôte de votre fournisseur de cloud comme `external_url`, par exemple `*.cloudapp.azure.com`, Let's Encrypt appliquerait des limites à `azure.com`, ce qui pourrait rendre la création du certificat incomplète.

  Dans ce cas, vous pouvez essayer de renouveler manuellement les certificats Let's Encrypt :

  ```shell
  sudo gitlab-ctl renew-le-certs
  ```

## Utilisation d'un certificat CA interne avec GitLab {#using-an-internal-ca-certificate-with-gitlab}

Après avoir configuré une instance GitLab avec un certificat CA interne, il se peut que vous ne puissiez pas y accéder à l'aide de divers outils CLI. Vous pouvez rencontrer les problèmes suivants :

- `curl` échoue :

  ```shell
  curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: unable to get local issuer certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Les tests à l'aide de la [console Rails](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session) échouent également :

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

- L'erreur `SSL certificate problem: unable to get local issuer certificate` s'affiche lors de la configuration d'un [miroir](https://docs.gitlab.com/user/project/repository/mirror/) à partir de cette instance GitLab.
- `openssl` fonctionne lorsque le chemin d'accès au certificat est spécifié :

  ```shell
  /opt/gitlab/embedded/bin/openssl s_client -CAfile /root/my-cert.crt -connect gitlab.domain.tld:443
  ```

Si vous rencontrez les problèmes décrits précédemment, ajoutez votre certificat à `/etc/gitlab/trusted-certs`, puis exécutez `sudo gitlab-ctl reconfigure`.

## Erreur de discordance des valeurs de clé X.509 {#x509-key-values-mismatch-error}

Après avoir configuré votre instance avec un bundle de certificats, NGINX peut afficher le message d'erreur suivant :

`SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch`

Ce message d'erreur signifie que le certificat serveur et la clé que vous avez fournis ne correspondent pas. Vous pouvez le confirmer en exécutant la commande suivante et en comparant les sorties :

```shell
openssl rsa -noout -modulus -in path/to/your/.key | openssl md5
openssl x509 -noout -modulus -in path/to/your/.crt | openssl md5
```

Voici un exemple de sortie md5 entre une clé et un certificat correspondants. Notez les hachages md5 correspondants :

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
4f49b61b25225abeb7542b29ae20e98c
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

Voici une sortie opposée avec une clé et un certificat non correspondants, qui affiche des hachages md5 différents :

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
d418865077299af27707b1d1fa83cd99
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

Si les deux sorties diffèrent comme dans l'exemple précédent, il y a une discordance entre le certificat et la clé. Contactez le fournisseur du certificat SSL pour obtenir une assistance supplémentaire.

## Erreur : `certificate signed by unknown authority` {#error-certificate-signed-by-unknown-authority}

En plus des erreurs mentionnées dans [Utilisation d'un certificat CA interne avec GitLab](ssl_troubleshooting.md#using-an-internal-ca-certificate-with-gitlab), vos pipelines CI peuvent se bloquer à l'état `Pending`. Dans les journaux du runner, vous pouvez voir le message d'erreur suivant :

```shell
Dec  6 02:43:17 runner-host01 gitlab-runner[15131]: #033[0;33mWARNING: Checking for jobs... failed
#033[0;m  #033[0;33mrunner#033[0;m=Bfkz1fyb #033[0;33mstatus#033[0;m=couldn't execute POST against
https://gitlab.domain.tld/api/v4/jobs/request: Post https://gitlab.domain.tld/api/v4/jobs/request:
x509: certificate signed by unknown authority
```

Suivez les instructions dans [Certificats auto-signés ou autorités de certification personnalisées pour GitLab Runner](https://docs.gitlab.com/runner/configuration/tls-self-signed/).

## Mise en miroir d'un dépôt GitLab distant utilisant un certificat SSL auto-signé {#mirroring-a-remote-gitlab-repository-that-uses-a-self-signed-ssl-certificate}

Lors de la configuration d'une instance GitLab locale pour [mettre en miroir un dépôt](https://docs.gitlab.com/user/project/repository/mirror/) à partir d'une instance GitLab distante qui utilise un certificat auto-signé, vous pouvez voir le message d'erreur `SSL certificate problem: self signed certificate` dans l'interface utilisateur.

La cause du problème peut être confirmée en vérifiant si :

- `curl` échoue :

  ```shell
  $ curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: self signed certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Les tests à l'aide de la console Rails échouent également :

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

Pour résoudre ce problème :

- Ajoutez le certificat auto-signé de l'instance GitLab distante au répertoire `/etc/gitlab/trusted-certs` sur l'instance GitLab locale, puis exécutez `sudo gitlab-ctl reconfigure` conformément aux instructions d'[installation des certificats publics personnalisés](_index.md#install-custom-public-certificates).
- Si votre instance GitLab locale a été installée à l'aide des charts Helm, vous pouvez [ajouter votre certificat auto-signé à votre instance GitLab](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#access-gitlab-with-a-custom-certificate).

Vous pouvez également recevoir un autre message d'erreur lorsque vous essayez de mettre en miroir un dépôt à partir d'une instance GitLab distante qui utilise un certificat auto-signé :

```shell
2:Fetching remote upstream failed: fatal: unable to access &amp;#39;https://gitlab.domain.tld/root/test-repo/&amp;#39;:
SSL: unable to obtain common name from peer certificate
```

Dans ce cas, le problème peut être lié au certificat lui-même :

1. Validez que votre certificat auto-signé ne manque pas d'un nom commun. Si c'est le cas, régénérez un certificat valide
1. Ajoutez le certificat à `/etc/gitlab/trusted-certs`.
1. Exécutez `sudo gitlab-ctl reconfigure`.

## Impossible d'effectuer des opérations Git en raison d'un certificat interne ou auto-signé {#unable-to-perform-git-operations-due-to-an-internal-or-self-signed-certificate}

Si votre instance GitLab utilise un certificat auto-signé, ou si le certificat est signé par une autorité de certification (CA) interne, vous pouvez rencontrer les erreurs suivantes lors de tentatives d'opérations Git :

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

Pour résoudre ce problème :

- Si possible, utilisez des accès distants SSH pour toutes les opérations Git. Cela est considéré comme plus sûr et plus pratique à utiliser.
- Si vous devez utiliser des accès distants HTTPS, vous pouvez essayer ce qui suit :
  - Copiez le certificat auto-signé ou le certificat CA racine interne dans un répertoire local (par exemple, `~/.ssl`) et configurez Git pour faire confiance à votre certificat :

    ```shell
    git config --global http.sslCAInfo ~/.ssl/gitlab.domain.tld.crt
    ```

  - Désactivez la vérification SSL dans votre client Git. Il s'agit d'une mesure temporaire, car elle pourrait être considérée comme un risque de sécurité.

    ```shell
    git config --global http.sslVerify false
    ```

## SSL_connect numéro de version incorrect {#ssl_connect-wrong-version-number}

Une mauvaise configuration peut entraîner :

- des entrées dans `gitlab-rails/exceptions_json.log` contenant :

  ```plaintext
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  ```

- `gitlab-workhorse/current` contenant :

  ```plaintext
  http: server gave HTTP response to HTTPS client
  http: server gave HTTP response to HTTPS client
  ```

- `gitlab-rails/sidekiq.log` ou `sidekiq/current` contenant :

  ```plaintext
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  ```

Certaines de ces erreurs proviennent du gem Ruby Excon et peuvent être générées dans des situations où GitLab est configuré pour initier une session HTTPS vers un serveur distant qui ne sert que du HTTP.

L'un des scénarios est que vous utilisez le [stockage d'objets](https://docs.gitlab.com/administration/object_storage/), qui n'est pas servi via HTTPS. GitLab est mal configuré et tente une négociation TLS, mais le stockage d'objets répond en HTTP simple.

## `schannel: SEC_E_UNTRUSTED_ROOT` {#schannel-sec_e_untrusted_root}

Si vous êtes sur Windows et obtenez l'erreur suivante :

```plaintext
Fatal: unable to access 'https://gitlab.domain.tld/group/project.git': schannel: SEC_E_UNTRUSTED_ROOT (0x80090325) - The certificate chain was issued by an authority that is not trusted."
```

Vous devez spécifier que Git doit utiliser OpenSSL :

```shell
git config --system http.sslbackend openssl
```

Vous pouvez également ignorer la vérification SSL en exécutant :

> [!warning]
> Procédez avec prudence lorsque vous [ignorez SSL](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpsslVerify) en raison des problèmes de sécurité potentiels associés à la désactivation de cette option au niveau global. Utilisez cette option _uniquement_ lors du dépannage, et rétablissez immédiatement la vérification SSL après.

```shell
git config --global http.sslVerify false
```

## Mise à niveau vers OpenSSL 3 {#upgrade-to-openssl-3}

À partir de la [version 17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770), GitLab utilise OpenSSL 3. Certains des anciens protocoles TLS et suites de chiffrement, ou les certificats TLS plus faibles pour les intégrations externes, peuvent être incompatibles avec les paramètres par défaut d'OpenSSL 3.

Avec la mise à niveau vers OpenSSL 3 :

- TLS 1.2 ou supérieur est requis pour toutes les connexions TLS entrantes et sortantes.
- Les certificats TLS doivent avoir au moins 112 bits de sécurité. Les clés RSA, DSA et DH de moins de 2048 bits, et les clés ECC de moins de 224 bits sont interdites.

Vous pouvez rencontrer l'un des messages d'erreur suivants :

- `no protocols available` lorsque la connexion TLS utilise un protocole antérieur à TLS 1.2.
- `certificate key too weak` lorsque le certificat TLS a moins de 112 bits de sécurité.
- `unsupported cipher algorithm` lorsqu'un chiffrement hérité est demandé.

Utilisez le [guide OpenSSL 3](openssl_3.md) pour identifier et évaluer la compatibilité de vos intégrations externes.
