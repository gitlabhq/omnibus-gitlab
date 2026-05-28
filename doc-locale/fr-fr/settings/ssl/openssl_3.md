---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mise à niveau vers OpenSSL 3
---

À partir de la [version 17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770), GitLab utilise OpenSSL 3. Cette version d'OpenSSL est une release majeure avec des dépréciations notables et des modifications du comportement par défaut d'OpenSSL (pour plus de détails, consultez le [guide de migration OpenSSL 3](https://docs.openssl.org/3.0/man7/migration_guide/)).

Certaines versions plus anciennes de TLS et suites de chiffrement pour les intégrations externes peuvent ne pas être compatibles avec ces modifications. Par conséquent, il est crucial d'évaluer la compatibilité de vos intégrations externes avant de procéder à la mise à niveau vers une version de GitLab qui utilise OpenSSL 3.

Avec la mise à niveau vers OpenSSL 3 :

- TLS 1.2 ou version ultérieure est requis pour toutes les connexions TLS entrantes et sortantes.
- Les certificats TLS doivent avoir au moins 112 bits de sécurité. Les clés RSA, DSA et DH de moins de 2048 bits, et les clés ECC de moins de 224 bits sont interdites.

## Aucune mise à niveau du système d'exploitation nécessaire {#no-operating-system-upgrades-needed}

Aucune mise à niveau du système d'exploitation n'est nécessaire pour que GitLab prenne en charge OpenSSL 3. Pour les packages Linux et le chart Helm, GitLab CE et EE embarquent leur propre version d'OpenSSL et n'utilisent pas la version d'OpenSSL du système d'exploitation. Cependant, les [builds FIPS](https://docs.gitlab.com/development/fips_gitlab/) utilisent bien l'OpenSSL du système d'exploitation, car cette bibliothèque est censée être certifiée FIPS.

## Identification des intégrations externes {#identifying-external-integrations}

Les intégrations externes peuvent être configurées soit avec `gitlab.rb` soit via l'interface web GitLab sous les **Paramètres** du projet, du groupe ou de l'administration.

Voici une liste préliminaire des intégrations que vous pouvez utiliser :

- Authentification et autorisation
  - [Serveurs LDAP](https://docs.gitlab.com/administration/auth/ldap/)
  - [Fournisseurs OmniAuth](https://docs.gitlab.com/integration/omniauth/), en particulier les fournisseurs peu courants, par exemple pour SAML ou Shibboleth.
  - [Applications autorisées](https://docs.gitlab.com/integration/oauth_provider/#view-all-authorized-applications)
- E-mail
  - [E-mail entrant](https://docs.gitlab.com/administration/incoming_email/#configuration-examples)
  - [Service Desk](https://docs.gitlab.com/user/project/service_desk/configure/)
  - [Serveurs SMTP](../smtp.md)
- [Intégrations de projets](https://docs.gitlab.com/user/project/integrations/)
- [Systèmes de suivi de tickets externes](https://docs.gitlab.com/integration/external-issue-tracker/)
- [Webhooks](https://docs.gitlab.com/user/project/integrations/webhooks/)
- [PostgreSQL externe](https://docs.gitlab.com/administration/postgresql/external/)
- [Redis externe](https://docs.gitlab.com/administration/redis/replication_and_failover_external/)
- [Stockage d'objets](https://docs.gitlab.com/administration/object_storage/)
- [ClickHouse](https://docs.gitlab.com/integration/clickhouse/)
- Surveillance
  - [Serveur Prometheus externe](https://docs.gitlab.com/administration/monitoring/prometheus/#using-an-external-prometheus-server)
  - [Grafana](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/)
  - [Prometheus distant](../prometheus.md#remote-readwrite)

Tous les composants fournis avec le package Linux sont compatibles avec OpenSSL 3. Par conséquent, vous n'avez besoin de vérifier que les services qui ne font pas partie du package GitLab et qui sont « externes ».

## Évaluation de la compatibilité avec OpenSSL 3 {#assessing-compatibility-with-openssl-3}

Vous pouvez utiliser différents outils pour vérifier la compatibilité des points de terminaison des intégrations externes. Quel que soit l'outil que vous utilisez, vous devez vérifier la version TLS prise en charge et les suites de chiffrement.

### Outil de ligne de commande `openssl` {#openssl-command-line-tool}

Vous pouvez utiliser l'outil de ligne de commande [`openssl s_client`](https://docs.openssl.org/3.0/man1/openssl-s_client/) pour vous connecter à un serveur compatible TLS. Il dispose d'un large éventail d'options que vous pouvez utiliser pour imposer des versions TLS ou des chiffrements spécifiques.

1. Avec le client système `openssl`, assurez-vous d'utiliser l'outil de ligne de commande OpenSSL 3 en vérifiant la version :

   ```shell
   openssl version
   ```

   Vous effectuez cette vérification avec le client OpenSSL système pour garantir la compatibilité lorsque [la version d'OpenSSL fournie avec GitLab](_index.md#details-on-how-gitlab-and-ssl-work) a été mise à niveau vers la version 3.

1. Utilisez l'exemple de script shell suivant pour vérifier si un serveur prend en charge les chiffrements et les versions TLS :

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

Dans certains cas, par exemple lors d'une connexion à une base de données PostgreSQL ou à un serveur SMTP, vous devez fournir l'option `-starttls` pour établir une connexion TLS. Consultez la [documentation OpenSSL](https://docs.openssl.org/master/man1/openssl-s_client/#options) pour plus de détails. Par exemple :

```shell
openssl s_client -connect YOUR_DATABASE_SERVER:5432 -tls1_2 -starttls postgres
```

### Script Nmap `ssl-enum-ciphers` {#nmap-ssl-enum-ciphers-script}

Le [script `ssl-enum-ciphers`](https://nmap.org/nsedoc/scripts/ssl-enum-ciphers.html) de Nmap identifie les versions TLS et les chiffrements pris en charge et fournit un résultat détaillé.

1. [Installer `nmap`](https://nmap.org/book/install.html).
1. Vérifiez que la version que vous utilisez est compatible avec OpenSSL 3 :

   ```shell
   nmap --version
   ```

   La sortie doit afficher les détails de la version, y compris la version d'OpenSSL avec laquelle Nmap est « compilé ».

1. Exécutez `nmap` sur le site que vous testez :

   ```shell
   nmap -sV --script ssl-enum-ciphers -p PORT HOST
   ```

   Vous devriez voir une sortie similaire à la suivante :

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
