---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sauvegarde
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Sauvegarde et restauration de la configuration sur une installation de package Linux {#backup-and-restore-configuration-on-a-linux-package-installation}

Toute la configuration des installations de package Linux est stockée dans `/etc/gitlab`. Vous devez conserver une copie de vos [configurations et certificats](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#data-not-included-in-a-backup) dans un endroit sûr, séparé de vos sauvegardes d'application GitLab. Cela réduit le risque que vos données d'application chiffrées soient perdues, divulguées ou volées en même temps que les clés nécessaires pour les déchiffrer.

En particulier, le fichier `gitlab-secrets.json` (et éventuellement aussi le fichier `gitlab.rb`) contient des clés de chiffrement de base de données pour protéger les données sensibles dans la base de données SQL :

- Secrets utilisateur de l'[authentification à deux facteurs](https://docs.gitlab.com/security/two_factor_authentication/) (2FA)
- [Fichiers sécurisés](https://docs.gitlab.com/ci/secure_files/)

Si ces fichiers sont perdus, les utilisateurs utilisant la 2FA perdront l'accès à leur [compte GitLab](https://docs.gitlab.com/user/profile/) et les « variables sécurisées » seront perdues des configurations CI.

Pour sauvegarder votre configuration, exécutez `sudo gitlab-ctl backup-etc`. Une archive tar est créée dans `/etc/gitlab/config_backup/`. Le répertoire et les fichiers de sauvegarde ne seront lisibles que par root.

> [!note]
> L'exécution de `sudo gitlab-ctl backup-etc --backup-path <DIRECTORY>` placera la sauvegarde dans le répertoire spécifié. Le répertoire sera créé s'il n'existe pas. Les chemins absolus sont recommandés.

Pour créer une sauvegarde d'application quotidienne, modifiez la table cron pour l'utilisateur root :

```shell
sudo crontab -e -u root
```

La table cron apparaîtra dans un éditeur.

Saisissez la commande pour créer un fichier tar contenant le contenu de `/etc/gitlab/`. Par exemple, planifiez la sauvegarde pour qu'elle s'exécute chaque matin après un jour de semaine, du mardi (jour 2) au samedi (jour 6) :

```plaintext
15 04 * * 2-6  gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/
```

> [!note]
> Assurez-vous que `/secret/gitlab/backups/` existe.

Vous pouvez extraire le fichier tar comme suit.

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf gitlab_config_1487687824_2017_02_21.tar -C /
```

N'oubliez pas d'exécuter `sudo gitlab-ctl reconfigure` après avoir restauré une sauvegarde de configuration.

> [!note]
> Les clés d'hôte SSH de vos machines sont stockées à un emplacement séparé dans `/etc/ssh/`. Assurez-vous également de [sauvegarder et restaurer ces clés](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079) pour éviter les avertissements d'attaque de l'homme du milieu si vous devez effectuer une restauration complète de la machine.

### Limiter la durée de vie des sauvegardes de configuration (supprimer les anciennes sauvegardes) {#limit-backup-lifetime-for-configuration-backups-prune-old-backups}

Les sauvegardes de configuration GitLab peuvent être purgées en utilisant le même paramètre `backup_keep_time` qui est [utilisé pour les sauvegardes d'application GitLab](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#limit-backup-lifetime-for-local-files-prune-old-backups)

Pour utiliser ce paramètre, modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

Le paramètre par défaut de `backup_keep_time` est `0`, ce qui conserve toutes les sauvegardes de configuration et d'application GitLab.

Une fois qu'un `backup_keep_time` est défini, vous pouvez exécuter `sudo gitlab-ctl backup-etc --delete-old-backups` pour supprimer toutes les sauvegardes plus anciennes que l'heure actuelle moins le `backup_keep_time`.

Vous pouvez fournir le paramètre `--no-delete-old-backups` si vous souhaitez conserver toutes les sauvegardes existantes.

> [!warning]
> Si aucun paramètre n'est fourni, la valeur par défaut est `--delete-old-backups`, ce qui supprimera toutes les sauvegardes plus anciennes que l'heure actuelle moins le `backup_keep_time`, si `backup_keep_time` est supérieur à 0.

## Création d'une sauvegarde d'application {#creating-an-application-backup}

Pour créer une sauvegarde de vos dépôts et des métadonnées GitLab, suivez la [documentation sur la création de sauvegardes](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/).

La création de sauvegarde stockera un fichier tar dans `/var/opt/gitlab/backups`.

Si vous souhaitez stocker vos sauvegardes GitLab dans un répertoire différent, ajoutez le paramètre suivant dans `/etc/gitlab/gitlab.rb` et exécutez `sudo gitlab-ctl
reconfigure` :

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

## Création de sauvegardes pour les instances GitLab dans des conteneurs Docker {#creating-backups-for-gitlab-instances-in-docker-containers}

> [!warning]
> La commande de sauvegarde nécessite des [paramètres supplémentaires](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer) lorsque votre installation utilise PgBouncer, pour des raisons de performance ou lors de son utilisation avec un cluster Patroni.

Les sauvegardes peuvent être planifiées sur l'hôte en ajoutant `docker exec -t <your container name>` au début des commandes.

Sauvegarde de l'application :

```shell
docker exec -t <your container name> gitlab-backup
```

Sauvegarde de la configuration et des secrets :

```shell
docker exec -t <your container name> /bin/sh -c 'gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/'
```

> [!note]
> Pour conserver ces sauvegardes en dehors du conteneur, montez des volumes dans les répertoires suivants :

1. `/secret/gitlab/backups`.
1. `/var/opt/gitlab` pour [toutes les données d'application](https://docs.gitlab.com/install/docker/installation/#create-a-directory-for-the-volumes), y compris les sauvegardes.
1. `/var/opt/gitlab/backups` (facultatif). L'outil `gitlab-backup` écrit dans ce répertoire [par défaut](#creating-an-application-backup). Bien que ce répertoire soit imbriqué dans `/var/opt/gitlab`, [Docker trie ces montages](https://github.com/moby/moby/pull/8055), leur permettant de fonctionner en harmonie.

   Cette configuration permet, par exemple :

   - Les données d'application sur un stockage local ordinaire (via le deuxième montage).
   - Un volume de sauvegarde sur un stockage réseau (via le troisième montage).

## Restauration d'une sauvegarde d'application {#restoring-an-application-backup}

Consultez la [documentation sur la restauration](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/).

## Sauvegarde et restauration avec une base de données non packagée {#backup-and-restore-using-non-packaged-database}

Si vous utilisez une base de données non packagée, consultez la [documentation sur l'utilisation d'une base de données non packagée](database.md#using-a-non-packaged-postgresql-database-management-server).

## Téléversement des sauvegardes vers un stockage distant (cloud) {#upload-backups-to-remote-cloud-storage}

Pour plus de détails, consultez la [documentation sur les sauvegardes](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage).

## Gestion manuelle du répertoire de sauvegarde {#manually-manage-backup-directory}

Les installations de package Linux créent le répertoire de sauvegarde défini avec `gitlab_rails['backup_path']`. Le répertoire appartient à l'utilisateur qui exécute GitLab et dispose d'autorisations strictes pour n'être accessible qu'à cet utilisateur. Ce répertoire contiendra des archives de sauvegarde qui contiennent des informations sensibles. Dans certaines organisations, les autorisations doivent être différentes en raison, par exemple, de l'envoi des archives de sauvegarde hors site.

Pour désactiver la gestion du répertoire de sauvegarde, dans `/etc/gitlab/gitlab.rb`, définissez :

```ruby
gitlab_rails['manage_backup_path'] = false
```

> [!warning]
> Si vous définissez cette option de configuration, il vous appartient de créer le répertoire spécifié dans `gitlab_rails['backup_path']` et de définir les autorisations qui permettront à l'utilisateur spécifié dans `user['username']` d'avoir l'accès approprié. Ne pas le faire empêchera GitLab de créer l'archive de sauvegarde.

## Identifiants de sauvegarde de la base de données de métadonnées du registre de conteneurs {#container-registry-metadata-database-backup-credentials}

{{< history >}}

- [Introduit] dans GitLab [18.11](https://gitlab.com/groups/gitlab-org/-/work_items/21179).

{{< /history >}}

Lors de l'utilisation de `gitlab-backup` pour sauvegarder la base de données de métadonnées du registre de conteneurs, GitLab doit stocker les identifiants lui permettant de se connecter à la base de données PostgreSQL du registre. Ces identifiants sont écrits dans des fichiers restreints sur le disque et récupérés par l'outil de sauvegarde au moment de l'exécution.

### Activer le rôle de sauvegarde {#enable-the-backup-role}

Pour activer la création des fichiers d'identifiants du registre :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_role'] = true
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Installations à nœud unique {#single-node-installations}

Sur une installation à nœud unique où le registre de conteneurs est co-localisé avec GitLab, les paramètres de connexion à la base de données sont automatiquement dérivés de la configuration `registry['database']`. Vous devez uniquement définir les identifiants pour les rôles PostgreSQL de sauvegarde et de restauration :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_role'] = true

   # Credentials for the PostgreSQL role used when creating backups
   gitlab_rails['backup_registry_user']     = 'registry_backup'  # default
   gitlab_rails['backup_registry_password'] = '<backup_password>'

   # Credentials for the PostgreSQL role used when restoring backups
   gitlab_rails['restore_registry_user']     = 'registry_restore'  # default
   gitlab_rails['restore_registry_password'] = '<restore_password>'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Installations multi-nœuds (nœud de sauvegarde dédié) {#multi-node-installations-dedicated-backup-node}

Pour les installations multi-nœuds, ou lors de l'exécution de `gitlab-backup` sur un nœud de sauvegarde dédié où le registre de conteneurs n'est pas co-localisé, spécifiez les détails de connexion explicitement :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_role'] = true

   gitlab_rails['backup_registry']['database_connection'] = {
     'host'        => 'registry-db.example.com',
     'port'        => 5432,           # default
     'dbname'      => 'registry',     # default
     'sslmode'     => 'require',
     'sslcert'     => '/path/to/client.crt',
     'sslkey'      => '/path/to/client.key',
     'sslrootcert' => '/path/to/ca.crt'
   }

   gitlab_rails['backup_registry_user']      = 'registry_backup'
   gitlab_rails['backup_registry_password']  = '<backup_password>'
   gitlab_rails['restore_registry_user']     = 'registry_restore'
   gitlab_rails['restore_registry_password'] = '<restore_password>'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Fichiers d'identifiants {#credential-files}

Après `sudo gitlab-ctl reconfigure`, les fichiers suivants sont créés sous `/opt/gitlab/etc/gitlab-backup/env/` :

| Fichier | Variables d'environnement écrites |
| ---- | ----------------------------- |
| `env-connection` | `REGISTRY_DATABASE_HOST`, `REGISTRY_DATABASE_PORT`, `REGISTRY_DATABASE_NAME`, `REGISTRY_DATABASE_SSLMODE`, `REGISTRY_DATABASE_SSLCERT`, `REGISTRY_DATABASE_SSLKEY`, `REGISTRY_DATABASE_SSLROOTCERT` |
| `env-backup_user` | `REGISTRY_DATABASE_USER`, `REGISTRY_DATABASE_PASSWORD` (identifiants du rôle de sauvegarde) |
| `env-restore_user` | `REGISTRY_DATABASE_USER`, `REGISTRY_DATABASE_PASSWORD` (identifiants du rôle de restauration) |

Tous les fichiers appartiennent à `root:root` avec les autorisations `0400`. Le répertoire parent dispose des autorisations `0750`. Seules les variables avec des valeurs non vides sont écrites dans les fichiers.
