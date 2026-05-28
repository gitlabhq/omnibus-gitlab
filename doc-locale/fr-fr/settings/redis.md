---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration de Redis
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Utilisation d'une instance Redis locale alternative {#using-an-alternate-local-redis-instance}

Les installations de packages Linux incluent Redis par défaut. Pour diriger l'application GitLab vers votre propre instance Redis s'exécutant *localement* :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Disable the bundled Redis
   redis['enable'] = false

   # Redis via TCP
   gitlab_rails['redis_host'] = '127.0.0.1'
   gitlab_rails['redis_port'] = 6379

   # OR Redis via Unix domain sockets
   gitlab_rails['redis_socket'] = '/tmp/redis.sock' # defaults to /var/opt/gitlab/redis/redis.socket

   # Password to Authenticate to alternate local Redis if required
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Rendre Redis intégré accessible via TCP {#making-the-bundled-redis-reachable-via-tcp}

Utilisez les paramètres suivants si vous souhaitez rendre l'instance Redis gérée par le package Linux accessible via TCP :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   redis['port'] = 6379
   redis['bind'] = '127.0.0.1'
   redis['password'] = 'redis-password-goes-here'
   ```

1. Enregistrez le fichier et reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configuration d'un serveur Redis uniquement à l'aide du package Linux {#setting-up-a-redis-only-server-using-the-linux-package}

Si vous souhaitez configurer Redis sur un serveur distinct de l'application GitLab, vous pouvez utiliser le [Redis intégré d'une installation de package Linux](https://docs.gitlab.com/administration/redis/standalone/).

## Exécution avec plusieurs instances Redis {#running-with-multiple-redis-instances}

Voir <https://docs.gitlab.com/administration/redis/replication_and_failover/#running-multiple-redis-clusters>.

## Redis Sentinel {#redis-sentinel}

Voir <https://docs.gitlab.com/administration/redis/replication_and_failover/>.

## Utilisation de Redis dans une configuration de basculement {#using-redis-in-a-failover-setup}

Voir <https://docs.gitlab.com/administration/redis/replication_and_failover/>.

## Utilisation de Google Cloud Memorystore {#using-google-cloud-memorystore}

Google Cloud Memorystore [ne prend pas en charge la commande Redis `CLIENT`](https://cloud.google.com/memorystore/docs/redis/product-constraints#blocked_redis_commands). Par défaut, Sidekiq tente de définir `CLIENT` à des fins de débogage. Cela peut être désactivé via le paramètre de configuration suivant :

```ruby
gitlab_rails['redis_enable_client'] = false
```

## Augmentation du nombre de connexions Redis au-delà de la valeur par défaut {#increasing-the-number-of-redis-connections-beyond-the-default}

Par défaut, Redis n'accepte que 10 000 connexions client. Si vous avez besoin de plus de 10 000 connexions, définissez l'attribut `maxclients` selon vos besoins. Notez que l'ajustement de l'attribut `maxclients` implique que vous devrez également prendre en compte les paramètres système de `fs.file-max` (par exemple `sysctl -w fs.file-max=20000`)

```ruby
redis['maxclients'] = 20000
```

## Optimisation de la pile TCP pour Redis {#tuning-the-tcp-stack-for-redis}

Les paramètres suivants permettent d'activer une instance de serveur Redis plus performante. `tcp_timeout` est une valeur définie en secondes pendant laquelle le serveur Redis attend avant de mettre fin à une connexion TCP inactive. Le paramètre `tcp_keepalive` est un réglage configurable en secondes pour les ACK TCP envoyés aux clients en l'absence de communication.

```ruby
redis['tcp_timeout'] = "60"
redis['tcp_keepalive'] = "300"
```

## Annoncer l'IP à partir du nom d'hôte {#announce-ip-from-hostname}

Actuellement, la seule façon d'activer les noms d'hôte dans Redis est de définir `redis['announce_ip']`. Cependant, cela devrait être défini de manière unique pour chaque instance Redis. `announce_ip_from_hostname` est un booléen qui nous permet d'activer ou de désactiver cette option. Il récupère le nom d'hôte de manière dynamique, en le déduisant à partir de la commande `hostname -f`.

```ruby
redis['announce_ip_from_hostname'] = true
```

## Configurer l'instance du cache Redis comme LRU {#setting-the-redis-cache-instance-as-an-lru}

L'utilisation de plusieurs instances Redis vous permet de configurer Redis comme un [cache LRU (Least Recently Used)](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/). Notez que vous ne devez effectuer cette opération que pour les instances de cache Redis, de limite de débit et de cache de dépôt ; les instances de files d'attente Redis, d'état partagé et de tracechunks ne doivent jamais être configurées comme LRU, car elles contiennent des données (par exemple, des jobs Sidekiq) qui sont censées être persistantes.

Pour limiter l'utilisation de la mémoire à 32 Go, vous pouvez utiliser :

```ruby
redis['maxmemory'] = "32gb"
redis['maxmemory_policy'] = "allkeys-lru"
redis['maxmemory_samples'] = 5
```

## Utilisation de Secure Sockets Layer (SSL) {#using-secure-sockets-layer-ssl}

Vous pouvez configurer Redis pour qu'il s'exécute derrière SSL.

### Exécution du serveur Redis derrière SSL {#running-redis-server-behind-ssl}

1. Pour exécuter le serveur Redis derrière SSL, vous pouvez utiliser les paramètres suivants dans `/etc/gitlab/gitlab.rb`. Consultez la section TLS/SSL de [`redis.conf.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/redis/templates/default/redis.conf.erb) pour en savoir plus sur les valeurs possibles :

   ```ruby
   redis['tls_port']
   redis['tls_cert_file']
   redis['tls_key_file']
   ```

1. Après avoir spécifié les valeurs requises, reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Certains binaires `redis-cli` ne sont pas compilés avec la prise en charge de la connexion directe à un serveur Redis via TLS. Si votre `redis-cli` ne prend pas en charge l'option `--tls`, vous devrez utiliser quelque chose comme [`stunnel`](https://redis.io/blog/stunnel-secure-redis-ssl/) pour vous connecter au serveur Redis à l'aide de `redis-cli` à des fins de débogage.

### Connecter le client GitLab au serveur Redis via SSL {#make-gitlab-client-connect-to-redis-server-over-ssl}

Pour activer la prise en charge SSL du client GitLab :

1. Ajoutez la ligne suivante à `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['redis_ssl'] = true
   ```

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Certificats SSL {#ssl-certificates}

Si vous utilisez des certificats SSL personnalisés pour Redis, veillez à les ajouter aux [certificats de confiance](ssl/_index.md#install-custom-public-certificates).

## Commandes renommées {#renamed-commands}

Par défaut, la commande `KEYS` est désactivée en tant que mesure de sécurité.

Si vous souhaitez masquer ou désactiver cette commande, ou d'autres commandes, modifiez le paramètre `redis['rename_commands']` dans `/etc/gitlab/gitlab.rb` de la façon suivante :

```ruby
redis['rename_commands'] = {
  'KEYS': '',
  'OTHER_COMMAND': 'VALUE'
}
```

- `OTHER_COMMAND` est la commande que vous souhaitez modifier
- `VALUE` doit être l'une des valeurs suivantes :
  1. Un nouveau nom de commande.
  1. `''`, ce qui désactive complètement la commande.

Pour désactiver cette fonctionnalité :

1. Définissez `redis['rename_commands'] = {}` dans votre fichier `/etc/gitlab/gitlab.rb`
1. Exécutez `sudo gitlab-ctl reconfigure`

## Libération différée {#lazy-freeing}

Redis 4 a introduit la [libération différée (lazy freeing)](https://antirez.com/news/93). Cela peut améliorer les performances lors de la libération de grandes valeurs.

Ce paramètre est défini par défaut sur `false`. Pour l'activer, vous pouvez utiliser :

```ruby
redis['lazyfree_lazy_eviction'] = true
redis['lazyfree_lazy_expire'] = true
redis['lazyfree_lazy_server_del'] = true
redis['replica_lazy_flush'] = true
```

## I/O multi-thread {#threaded-io}

Redis 6 a introduit l'I/O multi-thread. Cela permet aux écritures de s'adapter à plusieurs cœurs.

Ce paramètre est désactivé par défaut. Pour l'activer, vous pouvez utiliser :

```ruby
redis['io_threads'] = 4
redis['io_threads_do_reads'] = true
```

### Délais d'attente du client {#client-timeouts}

Par défaut, le [client Ruby pour Redis](https://github.com/redis-rb/redis-client?tab=readme-ov-file#configuration) utilise une valeur par défaut d'1 seconde pour les délais d'attente de connexion, de lecture et d'écriture. Vous devrez peut-être ajuster ces valeurs pour tenir compte de la latence du réseau local. Par exemple, si vous voyez des erreurs `Connection timed out - user specified timeout`, vous devrez peut-être augmenter `connect_timeout` :

```ruby
gitlab_rails['redis_connect_timeout'] = 3
gitlab_rails['redis_read_timeout'] = 1
gitlab_rails['redis_write_timeout'] = 1
```

## Fournir une configuration sensible aux clients Redis sans stockage en texte clair {#provide-sensitive-configuration-to-redis-clients-without-plain-text-storage}

Pour plus d'informations, consultez l'exemple dans la [documentation de configuration](configuration.md#provide-redis-password-to-redis-server-and-client-components).

## Utilisation de Valkey à la place de Redis {#using-valkey-instead-of-redis}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113) dans GitLab 18.9 en tant que version [bêta](https://docs.gitlab.com/policy/development_stages_support/#beta).
- [Disponible de manière générale](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9383) dans GitLab 19.0.

{{< /history >}}

[Valkey](https://valkey.io/) est un magasin clé-valeur compatible avec Redis qui peut être utilisé comme remplacement direct de Redis. Valkey est compatible avec Redis OSS 7.2 et toutes les versions antérieures de Redis open source.

Lors de l'utilisation de Valkey :

- Le nom du service reste `redis`. Utilisez `gitlab-ctl restart redis` pour gérer le service, et non `gitlab-ctl restart valkey`.
- Les fichiers journaux sont écrits dans `/var/log/gitlab/redis/`, pas dans un répertoire `valkey` séparé.
- Le répertoire de données reste `/var/opt/gitlab/redis/`.
- Le fichier de configuration reste `redis.conf`.
- Les outils `gitlab-ctl` utilisent toujours `redis-cli` pour les interactions avec Redis.
- Lors de l'utilisation de `valkey-cli` pour le dépannage, utilisez le même socket, hôte et port que vous utiliseriez avec `redis-cli` :

  ```shell
  sudo /opt/gitlab/embedded/bin/valkey-cli -s /var/opt/gitlab/redis/redis.socket
  ```

Pour plus d'informations sur la migration de Redis vers Valkey, consultez la [documentation de migration Valkey](https://valkey.io/topics/migration/).

### Passer à Valkey {#switch-to-valkey}

Pour utiliser Valkey à la place de Redis :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   redis['backend'] = 'valkey'
   ```

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Lorsque `redis['backend']` est défini sur `valkey` :

- Le service Redis utilise `valkey-server` à la place de `redis-server`.
- Le service Sentinel utilise `valkey-sentinel` à la place de `redis-sentinel`.
- Tous les autres paramètres Redis (ports, mots de passe, chemins, etc.) restent les mêmes.

#### Gestion des services {#service-management}

Pour assurer la compatibilité ascendante et une transition transparente, la structure du service reste cohérente, que vous utilisiez Redis ou Valkey comme backend :

- Le nom du service est `redis`. Utilisez `gitlab-ctl restart redis` pour gérer le service.
- Les fichiers journaux sont écrits dans `/var/log/gitlab/redis/`.
- Le répertoire de données est `/var/opt/gitlab/redis/`.
- Le fichier de configuration est `redis.conf`.
- Les commandes `gitlab-ctl` utilisent l'outil CLI approprié (`redis-cli` ou `valkey-cli`) en fonction du backend configuré.
- Pour le dépannage, utilisez le script wrapper qui détecte automatiquement le backend actif :

  ```shell
  sudo gitlab-redis-cli
  ```

Pour plus d'informations sur la migration de Redis vers Valkey, consultez la [documentation de migration Valkey](https://valkey.io/topics/migration/).

## Dépannage {#troubleshooting}

### `x509: certificate signed by unknown authority` {#x509-certificate-signed-by-unknown-authority}

Ce message d'erreur suggère que les certificats SSL n'ont pas été correctement ajoutés à la liste des certificats de confiance du serveur. Pour vérifier si c'est le cas :

1. Vérifiez les journaux Workhorse dans `/var/log/gitlab/gitlab-workhorse/current`.
1. Si vous voyez des messages qui ressemblent à ceci :

   ```plaintext
   2018-11-14_05:52:16.71123 time="2018-11-14T05:52:16Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_05:52:16.74397 time="2018-11-14T05:52:16Z" level=error msg="unknown error" error="keywatcher: x509: certificate signed by unknown authority"
   ```

   La première ligne doit afficher `rediss` comme schéma avec l'adresse du serveur Redis. La deuxième ligne indique que le certificat n'est pas correctement approuvé sur ce serveur. Consultez la [section précédente](#ssl-certificates).

1. Vérifiez que le certificat SSL fonctionne via [ces étapes de dépannage](ssl/ssl_troubleshooting.md#custom-certificates-missing-or-skipped).

### Authentification NOAUTH requise {#noauth-authentication-required}

Un serveur Redis peut nécessiter l'envoi d'un mot de passe via un message `AUTH` avant d'accepter les commandes. Un message d'erreur `NOAUTH Authentication required` indique que le client n'envoie pas de mot de passe. Les journaux GitLab peuvent aider à résoudre cette erreur :

1. Vérifiez les journaux Workhorse dans `/var/log/gitlab/gitlab-workhorse/current`.
1. Si vous voyez des messages qui ressemblent à ceci :

   ```plaintext
   2018-11-14_06:18:43.81636 time="2018-11-14T06:18:43Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_06:18:43.86929 time="2018-11-14T06:18:43Z" level=error msg="unknown error" error="keywatcher: pubsub receive: NOAUTH Authentication required."
   ```

1. Vérifiez que le mot de passe du client Redis spécifié dans `/etc/gitlab/gitlab.rb` est correct :

   ```ruby
   gitlab_rails['redis_password'] = 'your-password-here'
   ```

1. Si vous utilisez le serveur Redis fourni par le package Linux, vérifiez que le serveur possède le même mot de passe :

   ```ruby
   redis['password'] = 'your-password-here'
   ```

### Réinitialisation de connexion Redis (ECONNRESET) {#redis-connection-reset-econnreset}

Si vous voyez `Redis::ConnectionError: Connection lost (ECONNRESET)` dans les journaux Rails de GitLab (`/var/log/gitlab-rails/production.log`), cela peut indiquer que le serveur attend une connexion SSL mais que le client n'est pas configuré pour l'utiliser.

1. Vérifiez que le serveur écoute réellement sur le port via SSL. Par exemple :

   ```shell
   /opt/gitlab/embedded/bin/openssl s_client -connect redis-server:6379
   ```

1. Vérifiez `/var/opt/gitlab/gitlab-rails/etc/resque.yml`. Vous devriez voir quelque chose comme :

   ```yaml
   production:
     url: rediss://:mypassword@redis-server:6379/
   ```

1. Si `redis://` est présent à la place de `rediss://`, le paramètre `redis_ssl` n'a peut-être pas été configuré correctement, ou l'étape de reconfiguration n'a peut-être pas été exécutée.

### Connexion à Redis via la CLI {#connecting-to-redis-via-the-cli}

Lors de la connexion à Redis pour le dépannage, vous pouvez utiliser :

- Redis via les sockets de domaine Unix :

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
  ```

- Redis via TCP :

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379
  ```

- Mot de passe pour l'authentification à Redis si nécessaire :

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379 -a <password>
  ```
