---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres de la base de données
---

{{< details >}}

- Édition :  Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab prend en charge uniquement le système de gestion de base de données PostgreSQL.

Vous avez donc deux options pour les serveurs de base de données à utiliser avec une installation de package Linux :

- Utiliser le serveur PostgreSQL inclus dans l'installation du package Linux (aucune configuration requise, recommandé).
- Utiliser un [serveur PostgreSQL externe](#using-a-non-packaged-postgresql-database-management-server).

## Utilisation du service de base de données PostgreSQL fourni avec le package Linux {#using-the-postgresql-database-service-shipped-with-the-linux-package}

### Reconfiguration et redémarrages de PostgreSQL {#reconfigure-and-postgresql-restarts}

Les installations de packages Linux redémarrent généralement tout service lors de la reconfiguration si les paramètres de configuration de ce service ont été modifiés dans le fichier `gitlab.rb`. PostgreSQL est unique en ce sens que certains de ses paramètres prennent effet avec un rechargement (HUP), tandis que d'autres nécessitent un redémarrage de PostgreSQL. Étant donné que les administrateurs souhaitent souvent avoir plus de contrôle sur le moment exact où PostgreSQL est redémarré, les installations de packages Linux sont configurées pour effectuer un rechargement de PostgreSQL lors de la reconfiguration, et non un redémarrage. Cela signifie que si vous modifiez un paramètre PostgreSQL nécessitant un redémarrage, vous devrez redémarrer PostgreSQL manuellement après la reconfiguration.

Le [modèle de configuration GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) identifie les paramètres PostgreSQL nécessitant un redémarrage et ceux ne nécessitant qu'un rechargement. Vous pouvez également exécuter une requête sur votre base de données pour déterminer si un paramètre individuel nécessite un redémarrage. Démarrez une console de base de données avec `sudo gitlab-psql`, puis remplacez `<setting name>` dans la requête suivante par le paramètre que vous modifiez :

```sql
SELECT name,setting FROM pg_settings WHERE context = 'postmaster' AND name = '<setting name>';
```

Si la modification du paramètre nécessite un redémarrage, la requête retournera le nom du paramètre et la valeur actuelle de ce paramètre dans l'instance PostgreSQL en cours d'exécution.

Lorsque vous reconfigurez GitLab (`gitlab-ctl reconfigure`), si des paramètres PostgreSQL sont en attente d'un redémarrage, la commande affiche un avertissement qui répertorie chaque paramètre en attente avec sa valeur active et sa valeur en attente.

> [!note]
> La vérification des paramètres en attente s'applique uniquement à PostgreSQL géré par le package Linux. Elle ne couvre pas les nœuds gérés par Patroni dans un cluster Patroni ou HA.

#### Redémarrage automatique lors du changement de version PostgreSQL {#automatic-restart-when-the-postgresql-version-changes}

Par défaut, les installations de packages Linux redémarrent automatiquement PostgreSQL lorsque la version sous-jacente change, comme suggéré par la [documentation upstream](https://www.postgresql.org/docs/17/upgrading.html). Ce comportement peut être contrôlé à l'aide du paramètre `auto_restart_on_version_change` disponible pour `postgresql` et `geo-postgresql`.

Pour désactiver les redémarrages automatiques lors du changement de version PostgreSQL :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   # For PostgreSQL/Patroni
   postgresql['auto_restart_on_version_change'] = false

   # For Geo PostgreSQL
   geo_postgresql['auto_restart_on_version_change'] = false
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Il est fortement recommandé de redémarrer PostgreSQL lorsque la version sous-jacente change, afin d'éviter des erreurs comme [celle liée au chargement des bibliothèques nécessaires](#could-not-load-library-plpgsqlso).

### Configuration de SSL {#configuring-ssl}

Les installations de packages Linux activent automatiquement SSL sur le serveur PostgreSQL, mais celui-ci acceptera par défaut les connexions chiffrées et non chiffrées. L'application de SSL nécessite l'utilisation de la configuration `hostssl` dans `pg_hba.conf`. Pour plus de détails, consultez la [documentation de `pg_hba.conf`](https://www.postgresql.org/docs/17/auth-pg-hba-conf.html).

La prise en charge de SSL dépend des fichiers suivants :

- Le certificat SSL public pour la base de données (`server.crt`).
- La clé privée correspondante pour le certificat SSL (`server.key`).
- Un bundle de certificats racine qui valide le certificat du serveur (`root.crt`). Par défaut, les installations de packages Linux utilisent le bundle de certificats intégré dans `/opt/gitlab/embedded/ssl/certs/cacert.pem`. Cela n'est pas requis pour les certificats auto-signés.

Un certificat auto-signé et une clé privée valables 10 ans sont générés par une installation de package Linux pour utilisation. Si vous préférez utiliser un certificat signé par une CA ou remplacer celui-ci par votre propre certificat auto-signé, suivez les étapes ci-dessous.

L'emplacement de ces fichiers peut être configurable, mais la clé privée doit être lisible par l'utilisateur `gitlab-psql`. Les installations de packages Linux gèrent les permissions des fichiers pour vous, mais si les chemins sont personnalisés, vous devez vous assurer que `gitlab-psql` peut accéder au répertoire dans lequel les fichiers sont placés.

Pour plus de détails, consultez la [documentation PostgreSQL](https://www.postgresql.org/docs/17/ssl-tcp.html).

Notez que `server.crt` et `server.key` peuvent être différents des certificats SSL par défaut utilisés pour accéder à GitLab. Par exemple, supposons que le nom d'hôte externe de votre base de données est `database.example.com`, et que votre nom d'hôte GitLab externe est `gitlab.example.com`. Vous aurez besoin soit d'un certificat générique pour `*.example.com`, soit de deux certificats SSL différents.

Les fichiers `ssl_cert_file`, `ssl_key_file` et `ssl_ca_file` indiquent à PostgreSQL où trouver le certificat, la clé et le bundle dans le système de fichiers. Ces modifications sont appliquées à `postgresql.conf`. Les directives `internal_certificate` et `internal_key` sont utilisées pour renseigner le contenu de ces fichiers. Le contenu peut être ajouté directement ou chargé depuis un fichier, comme indiqué dans l'exemple suivant.

Une fois ces fichiers disponibles, activez SSL :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   postgresql['ssl_cert_file'] = '/custom/path/to/server.crt'
   postgresql['ssl_key_file'] = '/custom/path/to/server.key'
   postgresql['ssl_ca_file'] = '/custom/path/to/bundle.pem'
   postgresql['internal_certificate'] = File.read('/custom/path/to/server.crt')
   postgresql['internal_key'] = File.read('/custom/path/to/server.key')
   ```

   Les chemins relatifs seront ancrés dans le répertoire de données PostgreSQL (`/var/opt/gitlab/postgresql/data` par défaut).

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour appliquer les modifications de configuration.
1. Redémarrez PostgreSQL pour que les modifications prennent effet :

   ```shell
   gitlab-ctl restart postgresql
   ```

   Si PostgreSQL ne parvient pas à démarrer, consultez les journaux (par exemple, `/var/log/gitlab/postgresql/current`) pour plus de détails.

#### Exiger SSL {#require-ssl}

1. Ajoutez ce qui suit dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour appliquer les modifications de configuration.

#### Désactivation de SSL {#disabling-ssl}

1. Ajoutez ce qui suit dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   postgresql['ssl'] = 'off'
   ```

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour appliquer les modifications de configuration.
1. Redémarrez PostgreSQL pour que les modifications prennent effet :

   ```shell
   gitlab-ctl restart postgresql
   ```

   Si PostgreSQL ne parvient pas à démarrer, consultez les journaux (par exemple, `/var/log/gitlab/postgresql/current`) pour plus de détails.

#### Vérification que SSL est utilisé {#verifying-that-ssl-is-being-used}

Pour déterminer si SSL est utilisé par les clients, vous pouvez exécuter :

```shell
sudo gitlab-rails dbconsole --database main
```

Au démarrage, vous devriez voir une bannière similaire à la suivante :

```plaintext
psql (13.14)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: on)
Type "help" for help.
```

Pour déterminer si les clients utilisent SSL, exécutez cette requête SQL :

```sql
SELECT * FROM pg_stat_ssl;
```

Par exemple :

```plaintext
gitlabhq_production=> select * from pg_stat_ssl;
 pid  | ssl | version |         cipher         | bits | compression |  clientdn
------+-----+---------+------------------------+------+-------------+------------
  384 | f   |         |                        |      |             |
  386 | f   |         |                        |      |             |
  998 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
  933 | f   |         |                        |      |             |
 1003 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1016 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1022 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1211 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1214 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1213 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1215 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1252 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           |
 1280 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
  382 | f   |         |                        |      |             |
  381 | f   |         |                        |      |             |
  383 | f   |         |                        |      |             |
(16 rows)
```

1. Les lignes ayant `t` dans la colonne `ssl` sont activées.
1. Les lignes ayant une valeur dans `clientdn` utilisent la méthode d'authentification `cert`

#### Configurer l'authentification client SSL {#configure-ssl-client-authentication}

Les certificats SSL clients peuvent être utilisés pour s'authentifier auprès du serveur de base de données. La création des certificats dépasse le cadre de `omnibus-gitlab`. Mais les utilisateurs disposant d'une solution de gestion de certificats SSL existante peuvent l'utiliser.

##### Configurer le serveur de base de données {#configure-the-database-server}

1. Créez un certificat et une clé pour le serveur, le nom commun doit correspondre au nom DNS du serveur
1. Copiez le certificat du serveur, la clé et le fichier CA sur le serveur PostgreSQL, et assurez-vous que les permissions sont correctes
   1. Le certificat doit appartenir à l'utilisateur de la base de données (par défaut : `gitlab-psql`)
   1. Le fichier de clé doit appartenir à l'utilisateur de la base de données, et ses permissions doivent être `0400`
   1. Le fichier CA doit appartenir à l'utilisateur de la base de données, et ses permissions doivent être `0400`

   > [!note]
   > N'utilisez pas les noms de fichiers `server.crt` ou `server.key` pour ces fichiers. Ces noms de fichiers sont réservés à l'usage interne de `omnibus-gitlab`.

1. Assurez-vous que le paramètre suivant est défini dans `gitlab.rb` :

   ```ruby
   postgresql['ssl_cert_file'] = 'PATH_TO_CERTIFICATE'
   postgresql['ssl_key_file'] = 'PATH_TO_KEY_FILE'
   postgresql['ssl_ca_file'] = 'PATH_TO_CA_FILE'
   postgresql['listen_address'] = 'IP_ADDRESS'
   postgresql['cert_auth_addresses'] = {
     'IP_ADDRESS' => {
       'database' => 'gitlabhq_production',
       'user' => 'gitlab'
     }
   }
   ```

   Définissez `listen_address` comme l'adresse IP du serveur que les clients utiliseront pour se connecter à la base de données. Assurez-vous que `cert_auth_addresses` contient une liste d'adresses IP ainsi que les bases de données et les utilisateurs autorisés à se connecter à la base de données. Vous pouvez utiliser la notation CIDR lors de la spécification de la clé pour `cert_auth_addresses` afin d'incorporer une plage d'adresses IP.

1. Exécutez `gitlab-ctl reconfigure`, puis `gitlab-ctl restart postgresql` pour que les nouveaux paramètres prennent effet.

#### Configurer le client Rails {#configure-the-rails-client}

Pour que le client Rails se connecte au serveur, vous aurez besoin d'un certificat et d'une clé avec le `commonName` défini sur `gitlab`, signé par une autorité de certification approuvée dans le fichier CA spécifié dans `ssl_ca_file` sur le serveur de base de données.

1. Configurez `gitlab.rb`

   ```ruby
   gitlab_rails['db_host'] = 'IP_ADDRESS_OR_HOSTNAME_OF_DATABASE_SERVER'
   gitlab_rails['db_sslcert'] = 'PATH_TO_CERTIFICATE_FILE'
   gitlab_rails['db_sslkey'] = 'PATH_TO_KEY_FILE'
   gitlab_rails['db_rootcert'] = 'PATH_TO_CA_FILE'
   ```

1. Exécutez `gitlab-ctl reconfigure` pour que le client Rails utilise les nouveaux paramètres
1. Suivez les étapes de [Vérification que SSL est utilisé](#verifying-that-ssl-is-being-used) pour vous assurer que l'authentification fonctionne.

### Configurer le serveur PostgreSQL packagé pour écouter sur TCP/IP {#configure-packaged-postgresql-server-to-listen-on-tcpip}

Le serveur PostgreSQL packagé peut être configuré pour écouter les connexions TCP/IP, avec la mise en garde que certains scripts non critiques s'attendent à des sockets UNIX et peuvent se comporter incorrectement.

Pour configurer l'utilisation de TCP/IP pour le service de base de données, apportez des modifications aux sections `postgresql` et `gitlab_rails` de `gitlab.rb`.

#### Configurer le bloc PostgreSQL {#configure-postgresql-block}

Les paramètres suivants sont affectés dans le bloc `postgresql` :

- `listen_address` : Contrôle l'adresse sur laquelle PostgreSQL écoutera.
- `port` : Contrôle le port sur lequel PostgreSQL écoute. La valeur par défaut est `5432`.
- `md5_auth_cidr_addresses` : Une liste de blocs d'adresses CIDR autorisés à se connecter au serveur, après authentification par mot de passe.
- `trust_auth_cidr_addresses` : Une liste de blocs d'adresses CIDR autorisés à se connecter au serveur, sans aucune authentification. Vous devez uniquement définir ce paramètre pour autoriser les connexions depuis les nœuds qui ont besoin de se connecter, comme GitLab Rails ou Sidekiq. Cela inclut les connexions locales lorsqu'ils sont déployés sur le même nœud ou depuis des composants tels que Postgres Exporter (`127.0.0.1/32`).
- `sql_user` : Contrôle le nom d'utilisateur attendu pour l'authentification MD5. Par défaut, il s'agit de `gitlab`, et ce n'est pas un paramètre obligatoire.
- `sql_user_password` : Définit le mot de passe que PostgreSQL acceptera pour l'authentification MD5.
- `sql_superuser_password` : définit le mot de passe pour le superutilisateur `gitlab-psql`. Requis lors de l'utilisation de `md5_auth_cidr_addresses` avec Patroni afin que Patroni puisse s'authentifier pour les opérations `pg_rewind`. Lorsqu'il est défini, le mot de passe est également renseigné automatiquement dans la configuration de Patroni.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432
   postgresql['md5_auth_cidr_addresses'] = %w()
   postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/24)
   postgresql['sql_user'] = "gitlab"

   ##! SQL_USER_PASSWORD_HASH can be generated using the command `gitlab-ctl pg-password-md5 'gitlab'`,
   ##! where 'gitlab' (single-quoted to avoid shell interpolation) is the name of the SQL user that connects to GitLab.
   ##! You will be prompted for a password which other clients will use to authenticate with database, such as `securesqlpassword` in the below section.
   postgresql['sql_user_password'] = "SQL_USER_PASSWORD_HASH"

   # force ssl on all connections defined in trust_auth_cidr_addresses and md5_auth_cidr_addresses
   postgresql['hostssl'] = true
   ```

1. Reconfigurez GitLab et redémarrez PostgreSQL :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

Tout client ou service GitLab qui se connectera via le réseau devra fournir les valeurs de `sql_user` pour le nom d'utilisateur, et le mot de passe fourni à la configuration lors de la connexion au serveur PostgreSQL. Ils doivent également se trouver dans le bloc réseau fourni à `md5_auth_cidr_addresses`

#### Configurer le bloc GitLab Rails {#configure-gitlab-rails-block}

Pour configurer l'application `gitlab-rails` afin qu'elle se connecte à la base de données PostgreSQL via le réseau, plusieurs paramètres doivent être configurés :

- `db_host` : Doit être défini sur l'adresse IP du serveur de base de données. Si cela se trouve sur la même instance que le service PostgreSQL, cela peut être `127.0.0.1` et ne nécessite pas d'authentification par mot de passe.
- `db_port` : Définit le port du serveur PostgreSQL auquel se connecter, et doit être défini si `db_host` est défini.
- `db_username` : Configure le nom d'utilisateur avec lequel se connecter à PostgreSQL. Par défaut, il s'agit de `gitlab`.
- `db_password` : Doit être fourni lors de la connexion à PostgreSQL via TCP/IP, et depuis une instance dans le bloc `postgresql['md5_auth_cidr_addresses']` des paramètres ci-dessus. Cela n'est pas requis si vous vous connectez à `127.0.0.1` et que vous avez configuré `postgresql['trust_auth_cidr_addresses']` pour l'inclure.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = "gitlab"
   gitlab_rails['db_password'] = "securesqlpassword"
   ```

1. Reconfigurez GitLab et redémarrez PostgreSQL :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

#### Appliquer et redémarrer les services {#apply-and-restart-services}

Après avoir effectué les modifications précédentes, un administrateur doit exécuter `gitlab-ctl reconfigure`. Si vous rencontrez des problèmes concernant le service qui n'écoute pas sur TCP, essayez de redémarrer directement le service avec `gitlab-ctl restart postgresql`.

Certains scripts inclus dans le package Linux (comme `gitlab-psql`) s'attendent à ce que les connexions à PostgreSQL soient gérées via le socket UNIX, et peuvent ne pas fonctionner correctement. Vous pouvez activer TCP/IP sans désactiver les sockets UNIX.

Pour tester l'accès depuis d'autres clients, vous pouvez exécuter :

```shell
sudo gitlab-rails dbconsole --database main
```

### Activation de l'archivage WAL (Write Ahead Log) de PostgreSQL {#enabling-postgresql-wal-write-ahead-log-archiving}

Par défaut, l'archivage WAL du PostgreSQL packagé n'est pas activé. Tenez compte des points suivants lors de l'activation de l'archivage WAL :

- Le niveau WAL doit être 'replica' ou supérieur (les options 9.6+ sont `minimal`, `replica` ou `logical`)
- L'augmentation du niveau WAL augmentera la quantité de stockage consommée lors des opérations régulières

Pour activer l'archivage WAL :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Replication settings
   postgresql['sql_replication_user'] = "gitlab_replicator"
   postgresql['wal_level'] = "replica"
       ...
       ...
   # Backup/Archive settings
   postgresql['archive_mode'] = "on"
   postgresql['archive_command'] = "/your/wal/archiver/here"
   postgresql['archive_timeout'] = "60"
   ```

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour que les modifications prennent effet. Cela entraînera un redémarrage de la base de données.

### Restreindre l'accès à la base de données entre les composants {#restrict-database-access-between-components}

Par défaut, PostgreSQL accorde le rôle implicite `PUBLIC` `CONNECT` sur chaque base de données. Par conséquent, chaque utilisateur de base de données géré par le package Linux peut se connecter à chaque base de données gérée. Par exemple, l'utilisateur `registry` peut se connecter à `gitlabhq_production`, et l'utilisateur `gitlab` peut se connecter à `registry`. La propriété des tables empêche toujours la lecture des données, mais un utilisateur connecté peut inspecter les métadonnées de la base de données.

Pour appliquer le principe du moindre privilège, activez la restriction d'accès :

```ruby
postgresql['restrict_database_access'] = true
```

Lorsqu'elle est activée, `gitlab-ctl reconfigure` effectue les opérations suivantes pour chaque base de données gérée :

- Crée un rôle de connexion `NOLOGIN` nommé `<database>_connect`.
- Accorde à ce rôle `CONNECT` sur la base de données et `USAGE` sur le schéma `public`.
- Accorde le rôle de connexion aux utilisateurs de la base de données qui ont besoin d'un accès.
- Accorde le rôle de connexion à `pgbouncer`, le seul utilisateur qui doit accéder à chaque base de données en pool pour exécuter sa requête d'authentification.
- Révoque le privilège implicite `PUBLIC` `CONNECT`.

Les octrois et la révocation s'exécutent dans une seule transaction, de sorte qu'un utilisateur légitime n'est jamais bloqué pendant la reconfiguration. La révocation est reportée à une reconfiguration ultérieure jusqu'à ce que chaque rôle requis, y compris `pgbouncer`, existe.

Ce paramètre est défini par défaut sur `false`, de sorte que les mises à niveau n'entraînent aucun changement de privilège. Ne l'activez qu'après avoir confirmé qu'aucun outil externe ne se connecte en tant qu'utilisateur d'un composant à la base de données d'un autre composant. Ce paramètre s'applique à toutes les bases de données gérées par Omnibus.

Les utilisateurs de sauvegarde et de restauration du registre de conteneurs constituent des exceptions au modèle de rôle de connexion. L'utilisateur de sauvegarde conserve un octroi `CONNECT` direct, et l'utilisateur de restauration est un `SUPERUSER`, de sorte que les deux contournent le rôle de connexion par base de données. Lorsque vous auditez `datacl`, attendez-vous à voir ces octrois directs en plus du rôle `<database>_connect`.

L'application des règles s'effectue uniquement sur le primaire PostgreSQL. Dans un cluster Patroni, les modifications se répliquent vers les nœuds de secours via le journal write-ahead. La réplication WAL, Patroni et Consul ne sont pas affectés, car la réplication utilise un type de connexion distinct et le contrôle du cluster s'exécute en tant que superutilisateur.

Pour plus d'informations, consultez [le ticket 9763](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/9763).

### Stocker les données PostgreSQL dans un répertoire différent {#store-postgresql-data-in-a-different-directory}

Par défaut, tout est stocké sous `/var/opt/gitlab/postgresql`, contrôlé par l'attribut `postgresql['dir']`.

Cela comprend :

- Le socket de base de données sera `/var/opt/gitlab/postgresql/.s.PGSQL.5432`. Ceci est contrôlé par `postgresql['unix_socket_directory']`.
- L'utilisateur système `gitlab-psql` aura son répertoire `HOME` défini sur ceci. Ceci est contrôlé par `postgresql['home']`.
- Les données réelles seront stockées dans `/var/opt/gitlab/postgresql/data`.

Pour modifier l'emplacement des données PostgreSQL

Si vous disposez d'une base de données existante, vous devez d'abord déplacer les données vers le nouvel emplacement.

> [!warning]
> Il s'agit d'une opération intrusive. Elle ne peut pas être effectuée sans interruption de service sur une installation existante

1. S'il s'agit d'une installation existante, arrêtez GitLab : `gitlab-ctl stop`.
1. Mettez à jour `postgresql['dir']` vers l'emplacement souhaité.
1. Exécutez `gitlab-ctl reconfigure`.
1. Démarrez GitLab `gitlab-ctl start`.

### Mettre à niveau le serveur PostgreSQL packagé {#upgrade-packaged-postgresql-server}

Si vous disposez d'un cluster Patroni (PostgreSQL HA) géré par GitLab, utilisez plutôt la documentation suivante :

- [Mise à niveau de la version majeure de PostgreSQL dans un cluster Patroni](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster)
- [Mise à niveau de PostgreSQL avec temps d'arrêt quasi nul dans un cluster Patroni](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster)

Le package Linux fournit la commande `gitlab-ctl pg-upgrade` pour mettre à jour le serveur PostgreSQL packagé vers une version ultérieure (si elle est incluse dans le package). Cela met à jour PostgreSQL vers la [version livrée par défaut](https://docs.gitlab.com/administration/package_information/postgresql_versions/) lors des mises à niveau de packages, sauf si vous avez spécifiquement [refusé](#opt-out-of-automatic-postgresql-upgrades).

Avant de mettre à niveau GitLab vers une version plus récente, consultez les [modifications spécifiques à la version](https://docs.gitlab.com/update/versions/) du package Linux pour voir :

- Quand une version de base de données a changé.
- Quand une mise à niveau est justifiée.

Il est important de lire entièrement cette section avant d'exécuter des commandes. Pour les installations à nœud unique, cette mise à niveau nécessite une interruption de service, car la base de données doit être arrêtée pendant la mise à niveau. La durée dépend de la taille de votre base de données.

> [!note]
> Si vous rencontrez des problèmes lors de la mise à niveau, signalez un ticket avec une description complète dans le [suivi des `omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab).

Pour mettre à niveau la version PostgreSQL, assurez-vous que :

- Vous exécutez la dernière version de GitLab qui prend en charge votre version actuelle de PostgreSQL.
- Si vous avez récemment effectué une mise à niveau, vous avez exécuté `sudo gitlab-ctl reconfigure` avec succès avant de continuer.
- Vous disposez d'un espace disque suffisant pour deux copies de votre base de données. _Ne tentez pas de mettre à niveau si vous ne disposez pas de suffisamment d'espace libre._

  - Vérifiez la taille de votre base de données à l'aide de `sudo du -sh /var/opt/gitlab/postgresql/data` (ou mettez à jour le chemin de votre base de données).
  - Vérifiez l'espace disponible à l'aide de `sudo df -h`. Si la partition où réside la base de données n'a pas assez d'espace, passez l'argument `--tmp-dir $DIR` à la commande. La tâche de mise à niveau inclut une vérification de l'espace disque disponible et abandonne la mise à niveau si les exigences ne sont pas satisfaites.
    - Si vous utilisez un répertoire temporaire personnalisé, assurez-vous qu'il dispose du bon propriétaire et du bon groupe. Exécutez `ls -la /var/opt/gitlab/postgresql/data` pour vérifier le propriétaire et le groupe, puis définissez la même propriété sur le répertoire temporaire avec `sudo chown <user>:<group> $DIR`. Pour les installations par défaut, le propriétaire est `gitlab-psql`, et la commande est `sudo chown gitlab-psql:gitlab-psql $DIR`.

Après avoir confirmé que la liste de contrôle ci-dessus est satisfaite, vous pouvez procéder à la mise à niveau :

```shell
sudo gitlab-ctl pg-upgrade
```

Pour mettre à niveau vers une version spécifique de PostgreSQL, utilisez le drapeau `-V` pour spécifier la version. Par exemple, pour mettre à niveau vers PostgreSQL 17 :

```shell
sudo gitlab-ctl pg-upgrade -V 17
```

> [!note]
> `pg-upgrade` peut prendre des arguments ; par exemple, vous pouvez définir le délai d'expiration pour l'exécution des commandes sous-jacentes (`--timeout=1d2h3m4s5ms`). Exécutez `gitlab-ctl pg-upgrade -h` pour voir la liste complète.

`gitlab-ctl pg-upgrade` effectue les étapes suivantes :

1. Vérifie que la base de données est dans un état connu et stable.
1. Vérifie s'il y a suffisamment d'espace disque libre et abandonne sinon. Vous pouvez ignorer cette vérification en ajoutant le drapeau `--skip-disk-check`.
1. Arrête la base de données existante et tout service inutile, et active la page de déploiement de GitLab.
1. Modifie les liens symboliques dans `/opt/gitlab/embedded/bin/` pour que PostgreSQL pointe vers la version plus récente de la base de données.
1. Crée un nouveau répertoire contenant une nouvelle base de données vide avec des paramètres régionaux correspondant à la base de données existante.
1. Utilise l'outil `pg_upgrade` pour copier les données de l'ancienne base de données vers la nouvelle.
1. Déplace l'ancienne base de données hors de chemin.
1. Déplace la nouvelle base de données vers l'emplacement attendu.
1. Appelle `sudo gitlab-ctl reconfigure` pour effectuer les modifications de configuration requises et démarre le nouveau serveur de base de données.
1. Exécute `ANALYZE` pour générer des statistiques de base de données.
1. Démarre les services restants et supprime la page de déploiement.
1. Si des erreurs sont détectées au cours de ce processus, il revient à l'ancienne version de la base de données.

Une fois la mise à niveau terminée, vérifiez que tout fonctionne comme prévu.

S'il y a eu une erreur dans la sortie lors de l'exécution de l'étape `ANALYZE`, votre mise à niveau fonctionnera toujours, mais les performances de la base de données seront médiocres jusqu'à ce que les statistiques de la base de données soient générées. Utilisez `gitlab-psql` pour déterminer si `ANALYZE` doit être exécuté manuellement :

```shell
sudo gitlab-psql -c "SELECT relname, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL AND last_autoanalyze IS NULL;"
```

Vous pouvez exécuter `ANALYZE` manuellement si la requête ci-dessus a retourné des lignes :

```shell
sudo gitlab-psql -c 'SET statement_timeout = 0; ANALYZE VERBOSE;'
```

Le temps d'exécution de la commande `ANALYZE` peut varier considérablement en fonction de la taille de votre base de données. Pour surveiller la progression de cette opération, vous pouvez exécuter périodiquement la requête suivante dans une autre session de console. La colonne `tables_remaining` devrait progressivement atteindre `0` :

```shell
sudo gitlab-psql -c "
SELECT
    COUNT(*) AS total_tables,
    SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
FROM pg_stat_user_tables;
"
```

Après avoir vérifié que votre instance GitLab fonctionne correctement, vous pouvez nettoyer les anciens fichiers de base de données :

```shell
sudo rm -rf /var/opt/gitlab/postgresql/data.<old_version>
sudo rm -f /var/opt/gitlab/postgresql-version.old
```

Vous pouvez trouver des détails sur les versions de PostgreSQL livrées avec diverses versions de GitLab dans [les versions de PostgreSQL livrées avec le package Linux](https://docs.gitlab.com/administration/package_information/postgresql_versions/).

#### Refuser les mises à niveau automatiques de PostgreSQL {#opt-out-of-automatic-postgresql-upgrades}

Pour refuser les mises à niveau automatiques de PostgreSQL lors des mises à niveau du package GitLab, exécutez :

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

Si vous utilisez l'image Docker, vous pouvez désactiver les mises à niveau automatiques en définissant la variable d'environnement `GITLAB_SKIP_PG_UPGRADE` sur `true`.

### Rétablir le serveur PostgreSQL packagé à la version précédente {#revert-packaged-postgresql-server-to-the-previous-version}

> [!warning]
> Cette opération rétablit votre base de données actuelle, y compris ses données, à son état avant votre dernière mise à niveau. Assurez-vous de créer une sauvegarde avant de tenter de rétablir votre base de données PostgreSQL packagée.

Les versions antérieures du package Linux regroupent plusieurs versions de PostgreSQL. Si vous utilisez l'une de ces versions, vous pouvez utiliser la commande `gitlab-ctl revert-pg-upgrade` pour revenir à une version antérieure de PostgreSQL prise en charge par le package Linux. Cette commande prend également en charge le drapeau `-V` pour spécifier une version cible. Par exemple, pour revenir à la version 14 de PostgreSQL :

```shell
gitlab-ctl revert-pg-upgrade -V 14
```

Si la version cible n'est pas spécifiée, la commande utilise la version dans `/var/opt/gitlab/postgresql-version.old` si disponible. Sinon, elle revient à la version par défaut livrée avec GitLab.

Si vous utilisez une version du package Linux qui ne fournit qu'une seule version de PostgreSQL, vous ne pouvez pas rétablir votre version PostgreSQL. Pour ces versions du package Linux, vous devez revenir à une version antérieure de GitLab pour utiliser une version antérieure de PostgreSQL.

### Configuration de plusieurs connexions à la base de données {#configuring-multiple-database-connections}

{{< history >}}

- La tâche Rake `gitlab:db:decomposition:connection_status` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111927) dans GitLab 15.11.

{{< /history >}}

Dans GitLab 16.0, GitLab utilise par défaut deux connexions à la base de données pointant vers la même base de données PostgreSQL.

Avant de mettre à niveau vers GitLab 16.0, vérifiez que le paramètre PostgreSQL `max_connections` est suffisamment élevé pour que plus de 50 % des connexions disponibles apparaissent comme inutilisées. Par exemple, si `max_connections` est défini à 100 et que vous voyez 75 connexions en cours d'utilisation, vous devez augmenter `max_connections` à au moins 150 avant la mise à niveau, car après la mise à niveau, les connexions en cours d'utilisation doubleront pour atteindre 150.

Vous pouvez vérifier cela en exécutant la tâche Rake suivante :

```shell
sudo gitlab-rake gitlab:db:decomposition:connection_status
```

Si la tâche indique que `max_connections` est suffisamment élevé, vous pouvez procéder à la mise à niveau.

## Utilisation d'un serveur de gestion de base de données PostgreSQL non packagé {#using-a-non-packaged-postgresql-database-management-server}

Par défaut, GitLab est configuré pour utiliser le serveur PostgreSQL inclus dans le package Linux. Vous pouvez également le reconfigurer pour utiliser une instance externe de PostgreSQL.

> [!warning]
> Si vous utilisez un serveur PostgreSQL non packagé, vous devez vous assurer que PostgreSQL est configuré conformément aux [exigences de la base de données](https://docs.gitlab.com/install/requirements/#postgresql).

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = 'USERNAME'
   gitlab_rails['db_password'] = 'PASSWORD'
   ```

   N'oubliez pas de supprimer les caractères de commentaire `#` au début de ces lignes.

   Notez que :

   - `/etc/gitlab/gitlab.rb` doit avoir les permissions de fichier `0600` car il contient des mots de passe en texte brut.
   - PostgreSQL autorise l'écoute sur [plusieurs adresses](https://www.postgresql.org/docs/11/runtime-config-connection.html)

     Si vous utilisez plusieurs adresses dans `gitlab_rails['db_host']`, séparées par des virgules, la première adresse de la liste sera utilisée pour la connexion.

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. [Amorcez la base de données](#seed-the-database-fresh-installs-only).
1. Facultatif. [Activez la base de données de métadonnées du registre de conteneurs](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/).

### Configuration de socket UNIX pour PostgreSQL non packagé {#unix-socket-configuration-for-non-packaged-postgresql}

Si vous souhaitez utiliser le serveur PostgreSQL de votre système (installé sur le même système que GitLab) au lieu de celui fourni avec GitLab, vous pouvez le faire en utilisant un socket UNIX :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   # The path where the socket lives
   gitlab_rails['db_host'] = '/var/run/postgresql/'
   ```

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```ruby
   sudo gitlab-ctl-reconfigure
   ```

### Configuration de SSL {#configuring-ssl-1}

#### Exiger SSL {#require-ssl-1}

1. Ajoutez ce qui suit dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour appliquer les modifications de configuration.

#### Exiger SSL et vérifier le certificat du serveur par rapport au bundle CA {#require-ssl-and-verify-server-certificate-against-ca-bundle}

PostgreSQL peut être configuré pour exiger SSL et vérifier le certificat du serveur par rapport à un bundle CA afin d'éviter l'usurpation d'identité. Le bundle CA spécifié dans `gitlab_rails['db_sslrootcert']` doit contenir à la fois les certificats racine et intermédiaires.

1. Ajoutez ce qui suit dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['db_sslmode'] = "verify-full"
   gitlab_rails['db_sslrootcert'] = "<full_path_to_your_ca-bundle.pem>"
   ```

   Si vous utilisez Amazon RDS pour votre serveur PostgreSQL, assurez-vous de télécharger et d'utiliser le [bundle CA combiné](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem) pour `gitlab_rails['db_sslrootcert']`. Plus d'informations à ce sujet peuvent être trouvées dans l'article [Utilisation de SSL/TLS pour chiffrer une connexion à une instance de base de données](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html) sur AWS.

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour appliquer les modifications de configuration.

### Sauvegarder et restaurer une base de données PostgreSQL non packagée {#backup-and-restore-a-non-packaged-postgresql-database}

Lors de l'utilisation des commandes de [sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command) et de [restauration](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations), GitLab tentera d'utiliser la commande packagée `pg_dump` pour créer un fichier de sauvegarde de la base de données et la commande packagée `psql` pour restaurer une sauvegarde. Cela ne fonctionnera que si elles sont les versions correctes. Vérifiez les versions des `pg_dump` et `psql` packagés :

```shell
/opt/gitlab/embedded/bin/pg_dump --version
/opt/gitlab/embedded/bin/psql --version
```

Si ces versions sont différentes de votre PostgreSQL externe non packagé, vous pouvez rencontrer la sortie d'erreur suivante lors de l'exécution de la [commande de sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command).

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 12.6
pg_dump: error: aborting because of server version mismatch
```

Dans cet exemple, l'erreur se produit sur GitLab 14.1 lors de l'utilisation de PostgreSQL version 13.3, au lieu de la [version PostgreSQL livrée par défaut](https://docs.gitlab.com/administration/package_information/postgresql_versions/) de 12.6.

Dans ce cas, vous devrez installer des outils correspondant à votre version de base de données, puis suivre les étapes ci-dessous. Il existe plusieurs façons d'installer les outils client PostgreSQL. Consultez <https://www.postgresql.org/download/> pour les options.

Une fois que les outils `psql` et `pg_dump` corrects sont disponibles sur votre système, suivez ces étapes, en utilisant le chemin correct vers l'emplacement où vous avez installé les nouveaux outils :

1. Ajoutez des liens symboliques vers les versions non packagées :

   ```shell
   ln -s /path/to/new/pg_dump /path/to/new/psql /opt/gitlab/bin/
   ```

1. Vérifiez les versions :

   ```shell
   /opt/gitlab/bin/pg_dump --version
   /opt/gitlab/bin/psql --version
   ```

   Elles doivent maintenant être identiques à celles de votre PostgreSQL externe non packagé.

Une fois cette opération effectuée, assurez-vous que les tâches de sauvegarde et de restauration utilisent les exécutables corrects en exécutant les commandes de [sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command) et de [restauration](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations).

### Mettre à niveau une base de données PostgreSQL non packagée {#upgrade-a-non-packaged-postgresql-database}

Vous pouvez mettre à niveau la base de données externe après avoir arrêté tous les processus connectés à la base de données (Puma, Sidekiq) :

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
```

Avant de procéder à la mise à niveau, notez ce qui suit :

- Vérifiez la compatibilité entre les versions de GitLab et les versions de PostgreSQL :
  - Renseignez-vous sur les versions de GitLab qui ont introduit une exigence de [version minimale de PostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql).
  - Renseignez-vous sur les changements significatifs apportés aux versions de PostgreSQL [livrées avec le package Linux](https://docs.gitlab.com/administration/package_information/postgresql_versions/) : Le package Linux est testé pour la compatibilité avec les versions majeures de PostgreSQL qu'il fournit.
- Lors de l'utilisation de la sauvegarde ou de la restauration GitLab, vous devez conserver la même version de GitLab. Si vous prévoyez également de mettre à niveau vers une version ultérieure de GitLab, mettez d'abord à niveau PostgreSQL.
- Les [commandes de sauvegarde et de restauration](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command) peuvent être utilisées pour sauvegarder et restaurer la base de données vers une version ultérieure de PostgreSQL.
- Si une version de PostgreSQL est spécifiée avec `postgresql['version']` qui n'est pas livrée avec cette version du package Linux, la [version par défaut dans le tableau de compatibilité](https://docs.gitlab.com/administration/package_information/postgresql_versions/) détermine quels binaires clients (tels que les binaires de sauvegarde/restauration PostgreSQL) sont actifs.

L'exemple suivant illustre la mise à niveau d'un hôte de base de données exécutant PostgreSQL 16 vers un autre hôte de base de données exécutant PostgreSQL 17, avec une interruption de service :

1. Lancez un nouveau serveur de base de données PostgreSQL 17 configuré conformément aux [exigences de la base de données](https://docs.gitlab.com/install/requirements/#postgresql).
1. Assurez-vous que les versions compatibles de `pg_dump` et `pg_restore` sont utilisées sur l'instance GitLab Rails. Pour modifier la configuration de GitLab, modifiez `/etc/gitlab/gitlab.rb` et spécifiez la valeur de `postgresql['version']` :

   ```ruby
   postgresql['version'] = 17
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Arrêtez GitLab (notez que cette étape entraîne une interruption de service) :

   ```shell
   sudo gitlab-ctl stop
   ```

> [!warning]
> La commande de sauvegarde nécessite des [paramètres supplémentaires](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer) lorsque votre installation utilise PgBouncer.

1. Exécutez la tâche Rake de sauvegarde en utilisant les options SKIP pour sauvegarder uniquement la base de données. Notez le nom du fichier de sauvegarde ; vous l'utiliserez plus tard pour la restauration.

   ```shell
   sudo gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,pages,registry
   ```

1. Arrêtez l'hôte de base de données PostgreSQL 16.
1. Modifiez `/etc/gitlab/gitlab.rb` et mettez à jour le paramètre `gitlab_rails['db_host']` pour qu'il pointe vers l'hôte de base de données PostgreSQL 17.
1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   > [!warning]
   > La commande de sauvegarde nécessite des [paramètres supplémentaires](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer) lorsque votre installation utilise PgBouncer.

1. Restaurez la base de données à l'aide du fichier de sauvegarde créé précédemment, et assurez-vous de répondre **non** lorsqu'on vous demande « Cette tâche va maintenant reconstruire le fichier `authorized_keys` » :

   ```shell
   # Use the backup timestamp https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-timestamp
   sudo gitlab-backup restore BACKUP=<backup-timestamp>
   ```

1. Démarrez GitLab :

   ```shell
   sudo gitlab-ctl start
   ```

1. Après la mise à niveau de PostgreSQL vers une nouvelle version majeure, recréez les statistiques de table pour garantir que des plans de requête efficaces sont sélectionnés et pour réduire la charge CPU du serveur de base de données.

   Si la mise à niveau a été effectuée « en place » à l'aide de `pg_upgrade`, exécutez la requête suivante sur la console de base de données PostgreSQL :

   ```sql
   SET statement_timeout = 0; ANALYZE VERBOSE;
   ```

   Le temps d'exécution de la commande `ANALYZE` peut varier considérablement en fonction de la taille de votre base de données. Pour surveiller la progression de cette opération, vous pouvez exécuter périodiquement la requête suivante dans une autre console de base de données PostgreSQL. La colonne `tables_remaining` devrait progressivement atteindre `0` :

   ```sql
   SELECT
     COUNT(*) AS total_tables,
     SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
   FROM pg_stat_user_tables;
   ```

   Si la mise à niveau a utilisé `pg_dump` et `pg_restore`, exécutez la requête suivante sur la console de base de données PostgreSQL :

   ```sql
   SET statement_timeout = 0; VACUUM VERBOSE ANALYZE;
   ```

### Amorcer la base de données (nouvelles installations uniquement) {#seed-the-database-fresh-installs-only}

> [!warning]
> Il s'agit d'une commande destructive ; ne l'exécutez pas sur une base de données existante.

L'installation du package Linux n'amorce pas votre base de données externe. Exécutez la commande suivante pour importer le schéma et créer le premier utilisateur administrateur :

```shell
# Remove 'sudo' if you are the 'git' user
sudo gitlab-rake gitlab:setup
```

Si vous souhaitez spécifier un mot de passe pour l'utilisateur `root` par défaut, spécifiez le paramètre `initial_root_password` dans `/etc/gitlab/gitlab.rb` avant d'exécuter la commande `gitlab:setup` ci-dessus :

```ruby
gitlab_rails['initial_root_password'] = 'nonstandardpassword'
```

Si vous souhaitez spécifier le jeton d'enregistrement initial pour les runners GitLab partagés, spécifiez le paramètre `initial_shared_runners_registration_token` dans `/etc/gitlab/gitlab.rb` avant d'exécuter la commande `gitlab:setup` :

```ruby
gitlab_rails['initial_shared_runners_registration_token'] = 'token'
```

### Épingler la version PostgreSQL packagée (nouvelles installations uniquement) {#pin-the-packaged-postgresql-version-fresh-installs-only}

Le package Linux est livré avec [différentes versions de PostgreSQL](https://docs.gitlab.com/administration/package_information/postgresql_versions/) et initialise la version par défaut si aucune autre n'est spécifiée.

Pour initialiser PostgreSQL avec une version non par défaut, vous pouvez définir `postgresql['version']` sur la version majeure de l'une des [versions PostgreSQL packagées](https://docs.gitlab.com/administration/package_information/postgresql_versions/) avant la reconfiguration initiale. Par exemple, dans GitLab 18.11, vous pouvez utiliser `postgresql['version'] = 16` pour utiliser PostgreSQL 16 au lieu de PostgreSQL 17 par défaut.

> [!warning]
> La définition de `postgresql['version']` lors de l'utilisation du PostgreSQL packagé avec le package Linux après la reconfiguration initiale générera des erreurs indiquant que le répertoire de données a été initialisé sur une version différente de PostgreSQL. Si cela se produit, consultez [Rétablir le serveur PostgreSQL packagé à la version précédente](#revert-packaged-postgresql-server-to-the-previous-version).

Si vous effectuez une nouvelle installation sur un environnement où GitLab était précédemment installé et que vous utilisez une version PostgreSQL épinglée, assurez-vous d'abord que tous les dossiers liés à PostgreSQL sont supprimés et qu'aucun processus PostgreSQL n'est en cours d'exécution sur l'instance.

## Fournir une configuration de données sensibles à GitLab Rails sans stockage en texte brut {#provide-sensitive-data-configuration-to-gitlab-rails-without-plain-text-storage}

Pour plus d'informations, consultez l'exemple dans la [documentation de configuration](configuration.md#provide-the-postgresql-user-password-to-gitlab-rails).

## Paramètres d'application pour la base de données {#application-settings-for-the-database}

### Désactivation de la migration automatique de la base de données {#disabling-automatic-database-migration}

Si vous avez plusieurs serveurs GitLab partageant une base de données, vous souhaitez limiter le nombre de nœuds qui effectuent les étapes de migration lors de la reconfiguration.

Modifiez `/etc/gitlab/gitlab.rb` pour ajouter :

```ruby
# Enable or disable automatic database migrations
# on all hosts except the designated deploy node
gitlab_rails['auto_migrate'] = false
```

`/etc/gitlab/gitlab.rb` doit avoir les permissions de fichier `0600` car il contient des mots de passe en texte brut.

La prochaine fois que les hôtes portant la configuration ci-dessus seront reconfigurés, les étapes de migration ne seront pas effectuées.

Pour éviter les erreurs post-mise à niveau liées au schéma, l'hôte marqué comme [nœud de déploiement](https://docs.gitlab.com/update/zero_downtime/) doit avoir `gitlab_rails['auto_migrate'] = true` lors des mises à niveau.

### Définition du `statement_timeout` client {#setting-client-statement_timeout}

La durée pendant laquelle Rails attendra la fin d'une transaction de base de données avant d'expirer peut désormais être ajustée avec le paramètre `gitlab_rails['db_statement_timeout']`. Par défaut, ce paramètre n'est pas utilisé.

Modifiez `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_rails['db_statement_timeout'] = 45000
```

Dans ce cas, le `statement_timeout` client est défini à 45 secondes. La valeur est spécifiée en millisecondes.

### Définition du délai d'expiration de connexion {#setting-connection-timeout}

La durée pendant laquelle Rails attendra qu'une tentative de connexion à PostgreSQL réussisse avant d'expirer peut être ajustée avec le paramètre `gitlab_rails['db_connect_timeout']`. Par défaut, ce paramètre n'est pas utilisé :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['db_connect_timeout'] = 5
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Dans ce cas, le `connect_timeout` client est défini à 5 secondes. La valeur est spécifiée en secondes. Une valeur minimale de 2 secondes s'applique. Définir cette valeur à `<= 0` ou ne pas spécifier le paramètre du tout désactive le délai d'expiration.

### Définition des contrôles TCP {#setting-tcp-controls}

L'adaptateur PostgreSQL de Rails fournit une série de contrôles de connexion TCP qui peuvent être ajustés pour améliorer les performances. Consultez la [documentation upstream PostgreSQL pour plus d'informations sur chaque paramètre](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-KEEPALIVES).

Le package Linux ne définit aucune valeur par défaut pour ces valeurs et utilise à la place les valeurs par défaut fournies par l'adaptateur PostgreSQL. Remplacez-les dans `gitlab.rb` en utilisant les paramètres indiqués dans le tableau ci-dessous, puis exécutez `gitlab-ctl reconfigure`.

| Paramètre PostgreSQL  | Paramètre `gitlab.rb` |
|-----------------------|-----------------------|
| `keepalives`          | `gitlab_rails['db_keepalives']` |
| `keepalives_idle`     | `gitlab_rails['db_keepalives_idle']` |
| `keepalives_interval` | `gitlab_rails['db_keepalives_interval']` |
| `keepalives_count`    | `gitlab_rails['db_keepalives_count']` |
| `tcp_user_timeout`    | `gitlab_rails['db_tcp_user_timeout']` |

## Réindexation automatique de la base de données {#automatic-database-reindexing}

> [!warning]
> Il s'agit d'une fonctionnalité expérimentale qui n'est pas activée par défaut.

Recrée les index de base de données en arrière-plan (appelé « réindexation »). Cela peut être utilisé pour supprimer l'espace gonflé qui s'est accumulé dans les index et aide à maintenir des index sains et efficaces.

La tâche de réindexation peut être démarrée régulièrement via un cronjob. Pour configurer le cronjob, `gitlab_rails['database_reindexing']['enable']` doit être défini sur `true`.

Dans un environnement multi-nœuds, cette fonctionnalité ne doit être activée que sur un hôte d'application. Le processus de réindexation ne peut pas passer par PgBouncer, il doit disposer d'une connexion directe à la base de données.

Par défaut, cela démarre le cronjob toutes les heures pendant les week-ends (probablement une période à faible trafic) uniquement.

Vous pouvez modifier la planification en affinant les paramètres suivants :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```shell
   gitlab_rails['database_reindexing']['hour'] = '*'
   gitlab_rails['database_reindexing']['minute'] = 0
   gitlab_rails['database_reindexing']['month'] = '*'
   gitlab_rails['database_reindexing']['day_of_month'] = '*'
   gitlab_rails['database_reindexing']['day_of_week'] = '0,6'
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Si vous avez une instance Helm chart, vous pouvez à la place activer le CronJob de réindexation de base de données dans [le chart Toolbox](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#configure-periodic-database-reindexing).

## PostgreSQL packagé déployé dans un cluster HA/Geo {#packaged-postgresql-deployed-in-an-hageo-cluster}

### Mise à niveau d'un cluster GitLab HA {#upgrading-a-gitlab-ha-cluster}

Pour mettre à niveau la version de PostgreSQL dans un cluster Patroni, consultez [Mise à niveau de la version majeure de PostgreSQL dans un cluster Patroni](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster).

### Dépannage des mises à niveau dans un cluster HA {#troubleshooting-upgrades-in-an-ha-cluster}

Si, à un moment donné, le PostgreSQL packagé fonctionnait sur un nœud avant la mise à niveau vers une configuration HA, l'ancien répertoire de données peut subsister. Cela amènera `gitlab-ctl reconfigure` à rétrograder la version des utilitaires PostgreSQL qu'il utilise sur ce nœud. Déplacez (ou supprimez) le répertoire pour éviter cela :

- `mv /var/opt/gitlab/postgresql/data/ /var/opt/gitlab/postgresql/data.$(date +%s)`

Si vous rencontrez l'erreur suivante lors de la recréation des nœuds secondaires avec `gitlab-ctl repmgr standby setup MASTER_NODE_NAME`, assurez-vous que `postgresql['max_replication_slots'] = X` (où `X` est le nombre de nœuds DB + 1) est inclus dans `/etc/gitlab/gitlab.rb` :

```shell
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Mise à niveau d'une instance Geo {#upgrading-a-geo-instance}

Étant donné que Geo dépend par défaut de la réplication en continu de PostgreSQL, il existe des considérations supplémentaires lors de la mise à niveau de GitLab et/ou lors de la mise à niveau de PostgreSQL, décrites ci-dessous.

#### Mises en garde lors de la mise à niveau de PostgreSQL avec Geo {#caveats-when-upgrading-postgresql-with-geo}

> [!warning]
> Lors de l'utilisation de Geo, la mise à niveau de PostgreSQL nécessite une interruption de service sur tous les sites secondaires, car elle nécessite la réinitialisation de la réplication PostgreSQL vers les **sites secondaires** Geo. Cela est dû au fonctionnement de la réplication en continu de PostgreSQL. La réinitialisation de la réplication copie à nouveau toutes les données depuis le primaire, ce qui peut prendre beaucoup de temps en fonction principalement de la taille de la base de données et de la bande passante disponible. Par exemple, à une vitesse de transfert de 30 Mbps et une taille de base de données de 100 Go, la resynchronisation pourrait prendre environ 8 heures. Consultez la [documentation PostgreSQL](https://www.postgresql.org/docs/11/pgupgrade.html) pour plus d'informations.

#### Comment mettre à niveau PostgreSQL lors de l'utilisation de Geo {#how-to-upgrade-postgresql-when-using-geo}

Pour mettre à niveau PostgreSQL, vous aurez besoin du nom du slot de réplication et du mot de passe de l'utilisateur de réplication.

1. Trouvez le nom du slot de réplication existant sur le nœud de base de données du primaire Geo, exécutez :

   ```shell
   sudo gitlab-psql -qt -c 'select slot_name from pg_replication_slots'
   ```

   Si vous ne trouvez pas votre `slot_name` ici, ou si aucune sortie n'est retournée, vos sites secondaires Geo ne sont peut-être pas en bonne santé. Dans ce cas, assurez-vous que les [sites secondaires sont en bonne santé et que la réplication fonctionne](https://docs.gitlab.com/administration/geo/replication/troubleshooting/common/#health-check-rake-task).

   Même si la requête est vide, vous pouvez essayer de réinitialiser la base de données secondaire avec le `slot_name` trouvé dans la [zone d'administration des sites Geo](https://docs.gitlab.com/administration/geo_sites/).

1. Récupérez le mot de passe de l'utilisateur de réplication. Il a été défini lors de la configuration de Geo dans [Étape 1. Configurer le site primaire](https://docs.gitlab.com/administration/geo/setup/database/#step-1-configure-the-primary-site).

1. Facultatif. [Mettez en pause la réplication sur chaque site **secondaire**](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication) pour protéger leur capacité de reprise après sinistre (DR).

1. Mettez à niveau manuellement PostgreSQL sur le primaire Geo. Exécutez sur le nœud de base de données du primaire Geo :

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

   Attendez que la **base de données primaire** termine sa mise à niveau avant de commencer l'étape suivante, afin que le site secondaire puisse rester disponible comme sauvegarde. Ensuite, vous pouvez mettre à niveau la **base de données de suivi** en parallèle avec la **base de données secondaire**.

1. Mettez à niveau manuellement PostgreSQL sur les sites secondaires Geo. Exécutez sur la **base de données secondaire** Geo et également sur la **base de données de suivi** :

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

1. Redémarrez la réplication de base de données sur la **base de données secondaire** Geo à l'aide de la commande :

   ```shell
   sudo gitlab-ctl replicate-geo-database --slot-name=SECONDARY_SLOT_NAME --host=PRIMARY_HOST_NAME --sslmode=verify-ca
   ```

   Vous serez invité à saisir le mot de passe de l'utilisateur de réplication du primaire. Remplacez `SECONDARY_SLOT_NAME` par le nom du slot récupéré à la première étape ci-dessus.

   Le délai d'expiration par défaut pour cette opération est de 30 minutes. Si vous avez besoin d'augmenter le délai d'expiration, définissez l'option `--backup-timeout`. Par exemple, `--backup-timeout=21600` donne à la réplication initiale 6 heures pour se terminer.

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) sur la **base de données secondaire** Geo pour mettre à jour le fichier `pg_hba.conf`. Cela est nécessaire car `replicate-geo-database` réplique le fichier du primaire vers le secondaire.

1. Si vous avez mis en pause la réplication à l'étape 3, [reprenez la réplication sur chaque site **secondaire**](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication).

1. Redémarrez `puma`, `sidekiq` et `geo-logcursor`.

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. Accédez à `https://your_primary_server/admin/geo/sites` et assurez-vous que tous les sites Geo sont en bonne santé.

## Connexion à la base de données PostgreSQL {#connecting-to-the-postgresql-database}

Si vous avez besoin de vous connecter à la base de données PostgreSQL, vous pouvez vous connecter en tant qu'utilisateur de l'application :

```shell
sudo gitlab-rails dbconsole --database main
```

## Dépannage {#troubleshooting}

### Définir `default_transaction_isolation` sur `read committed` {#set-default_transaction_isolation-into-read-committed}

Si vous voyez des erreurs similaires à celles qui suivent dans votre journal `production/sidekiq` :

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

Il est probable que la configuration `default_transaction_isolation` de votre base de données n'est pas conforme aux exigences de l'application GitLab. Vous pouvez vérifier cette configuration en vous connectant à votre base de données PostgreSQL et en exécutant `SHOW default_transaction_isolation;`. L'application GitLab s'attend à ce que `read committed` soit configuré.

Cette configuration `default_transaction_isolation` est définie dans votre fichier `postgresql.conf`. Vous devrez redémarrer/recharger la base de données après avoir modifié la configuration. Cette configuration est incluse par défaut dans le serveur PostgreSQL packagé fourni avec le package Linux.

### Impossible de charger la bibliothèque `plpgsql.so` {#could-not-load-library-plpgsqlso}

Vous pourriez voir des erreurs similaires à celles qui suivent lors de l'exécution de migrations de base de données ou dans les journaux PostgreSQL/Patroni :

```plaintext
ERROR:  could not load library "/opt/gitlab/embedded/postgresql/12/lib/plpgsql.so": /opt/gitlab/embedded/postgresql/12/lib/plpgsql.so: undefined symbol: EnsurePortalSnapshotExists
```

Cette erreur est causée par le fait de ne pas avoir redémarré PostgreSQL après le changement de version sous-jacente. Pour corriger cette erreur :

1. Exécutez l'une des commandes suivantes :

   ```shell
   # For PostgreSQL
   sudo gitlab-ctl restart postgresql

   # For Patroni
   sudo gitlab-ctl restart patroni

   # For Geo PostgreSQL
   sudo gitlab-ctl restart geo-postgresql
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Charge CPU de la base de données très élevée {#database-cpu-load-very-high}

Si la charge CPU de la base de données est très élevée, cela pourrait être causé par le [paramètre d'annulation automatique des pipelines redondants](https://docs.gitlab.com/ci/pipelines/settings/#auto-cancel-redundant-pipelines). Pour plus de détails, consultez le [ticket 435250](https://gitlab.com/gitlab-org/gitlab/-/issues/435250).

Pour contourner ce problème :

- Vous pouvez allouer plus de ressources CPU au serveur de base de données.
- Si Sidekiq est surchargé, vous devrez peut-être [ajouter plus de processus Sidekiq](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#start-multiple-processes) pour la file d'attente `ci_cancel_redundant_pipelines` si vos projets ont un très grand nombre de pipelines.
- Vous pouvez activer le feature flag `disable_cancel_redundant_pipelines_service` pour désactiver ce paramètre à l'échelle de l'instance et voir si la charge CPU diminue. Cela désactive la fonctionnalité pour tous les projets, et peut entraîner une utilisation accrue des ressources par les pipelines qui ne sont plus annulés automatiquement.

### Erreur : `TypeError: can't quote Array` {#error-typeerror-cant-quote-array}

Si vous utilisez Amazon RDS, lors de la tâche `gitlab::database_migrations`, vous pourriez voir l'erreur : `TypeError: can't quote Array`.

Pour contourner ce [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/356307) , désactivez le paramètre [`quote_all_identifiers`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html) dans RDS pour une base de données PostgreSQL.
