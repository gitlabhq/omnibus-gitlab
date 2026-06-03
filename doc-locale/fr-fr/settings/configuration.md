---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Options de configuration pour les installations de packages Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour configurer GitLab, définissez les options pertinentes dans le fichier `/etc/gitlab/gitlab.rb`.

[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) contient une liste complète des options disponibles. Les nouvelles installations ont toutes les options du modèle listées dans `/etc/gitlab/gitlab.rb` par défaut.

> [!note]
> Les exemples fournis lorsque vous modifiez `/etc/gitlab/gitlab.rb` ne reflètent pas toujours les paramètres par défaut d'une instance.

Pour obtenir la liste des paramètres par défaut, consultez les [valeurs par défaut du package](https://docs.gitlab.com/administration/package_information/defaults/).

## Configurer l'URL externe pour GitLab {#configure-the-external-url-for-gitlab}

Pour afficher les liens de clonage de dépôt corrects à vos utilisateurs, vous devez fournir à GitLab l'URL que vos utilisateurs utilisent pour accéder au dépôt. Vous pouvez utiliser l'IP de votre serveur, mais un nom de domaine pleinement qualifié (FQDN) est préférable. Consultez la [documentation DNS](dns.md) pour plus de détails sur l'utilisation du DNS dans une instance GitLab Self-Managed.

Pour modifier l'URL externe :

1. Facultatif. Avant de modifier l'URL externe, déterminez si vous avez précédemment défini une [**URL de la page d'accueil** personnalisée ou un **After sign-out path**](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#sign-in-information). Ces deux paramètres peuvent provoquer des redirections non intentionnelles après la configuration d'une nouvelle URL externe. Si vous avez défini des URL, supprimez-les complètement.

1. Modifiez `/etc/gitlab/gitlab.rb` et remplacez `external_url` par l'URL de votre choix :

   ```ruby
   external_url "http://gitlab.example.com"
   ```

   Vous pouvez également utiliser l'adresse IP de votre serveur :

   ```ruby
   external_url "http://10.0.0.1"
   ```

   Dans les exemples précédents, nous utilisons le protocole HTTP simple. Si vous souhaitez utiliser HTTPS, consultez la procédure pour [configurer SSL](ssl/_index.md).

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Facultatif. Si vous utilisez GitLab depuis un certain temps, après avoir modifié l'URL externe, vous devriez également [invalider le cache Markdown](https://docs.gitlab.com/administration/invalidate_markdown_cache/).

### Spécifier l'URL externe au moment de l'installation {#specify-the-external-url-at-the-time-of-installation}

Si vous utilisez le package Linux, vous pouvez configurer votre instance GitLab avec un nombre minimal de commandes en utilisant la variable d'environnement `EXTERNAL_URL`. Si cette variable est définie, elle est automatiquement détectée et sa valeur est écrite en tant que `external_url` dans le fichier `gitlab.rb`.

La variable d'environnement `EXTERNAL_URL` n'affecte que l'installation et la mise à niveau des packages. Pour les exécutions de reconfiguration régulières, la valeur dans `/etc/gitlab/gitlab.rb` est utilisée.

Dans le cadre des mises à jour de packages, si vous avez défini la variable `EXTERNAL_URL` par inadvertance, elle remplace la valeur existante dans `/etc/gitlab/gitlab.rb` sans aucun avertissement. Nous recommandons donc de ne pas définir la variable globalement, mais plutôt de la passer spécifiquement à la commande d'installation :

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee
```

## Configurer une URL relative pour GitLab {#configure-a-relative-url-for-gitlab}

{{< details >}}

- Statut : Bêta

{{< /details >}}

> [!warning]
> La configuration d'une URL relative pour GitLab présente des [problèmes connus avec Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/456427) et des [limitations de test](https://gitlab.com/gitlab-org/gitlab/-/issues/439943).

Bien que nous recommandions d'installer GitLab dans son propre (sous-)domaine, cela n'est parfois pas possible. Dans ce cas, GitLab peut également être installé sous une URL relative, par exemple `https://example.com/gitlab`.

En modifiant l'URL, toutes les URL distantes changent également, vous devez donc les modifier manuellement dans tout dépôt local pointant vers votre instance GitLab.

Ces instructions s'appliquent aux installations de packages Linux. Pour les instructions relatives aux installations compilées manuellement (depuis les sources), consultez [installer GitLab sous une URL relative](https://docs.gitlab.com/install/relative_url/).

Pour activer l'URL relative dans GitLab :

1. Définissez `external_url` dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   external_url "https://example.com/gitlab"
   ```

   Dans cet exemple, l'URL relative sous laquelle GitLab est servi est `/gitlab`. Modifiez-la à votre convenance.

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Si vous rencontrez des problèmes, consultez la [section de dépannage](#relative-url-troubleshooting).

## Charger un fichier de configuration externe depuis un utilisateur non-root {#load-external-configuration-file-from-non-root-user}

Les installations de packages Linux chargent toute la configuration depuis le fichier `/etc/gitlab/gitlab.rb`. Ce fichier possède des permissions de fichier strictes et appartient à l'utilisateur `root`. La raison des permissions et de la propriété strictes est que `/etc/gitlab/gitlab.rb` est exécuté en tant que code Ruby par l'utilisateur `root` lors de l'exécution de `gitlab-ctl reconfigure`. Cela signifie que les utilisateurs ayant un accès en écriture à `/etc/gitlab/gitlab.rb` peuvent ajouter une configuration qui est exécutée en tant que code par `root`.

Dans certaines organisations, il est permis d'avoir accès aux fichiers de configuration, mais pas en tant qu'utilisateur root. Vous pouvez inclure un fichier de configuration externe dans `/etc/gitlab/gitlab.rb` en spécifiant le chemin d'accès au fichier :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   from_file "/home/admin/external_gitlab.rb"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Lorsque vous utilisez `from_file` :

- Le code que vous incluez dans `/etc/gitlab/gitlab.rb` à l'aide de `from_file` s'exécute avec les privilèges `root` lorsque vous reconfigurez GitLab.
- Toute configuration définie dans `/etc/gitlab/gitlab.rb` après l'inclusion de `from_file` prend la priorité sur la configuration du fichier inclus.

## Lire un certificat depuis un fichier {#read-certificate-from-file}

Les certificats peuvent être stockés sous forme de fichiers séparés et chargés en mémoire lors de l'exécution de `sudo gitlab-ctl reconfigure`. Les fichiers contenant des certificats doivent être en texte brut.

Dans cet exemple, le [certificat du serveur PostgreSQL](database.md#configuring-ssl) est lu directement depuis un fichier plutôt que copié-collé directement dans `/etc/gitlab/gitlab.rb`.

```ruby
postgresql['internal_certificate'] = File.read('/path/to/server.crt')
```

## Migration depuis `git_data_dirs` {#migrating-from-git_data_dirs}

À partir de la version 18.0, `git_data_dirs` ne sera plus un moyen pris en charge pour configurer les emplacements de stockage Gitaly. Si vous définissez explicitement `git_data_dirs`, vous devrez migrer la configuration.

Par exemple, pour le service Gitaly, si votre configuration `/etc/gitlab/gitlab.rb` est la suivante :

```ruby
git_data_dirs({
  "default" => {
    "path" => "/mnt/nas/git-data"
   }
})
```

vous devrez redéfinir la configuration sous `gitaly['configuration']` à la place. Notez que le suffixe `/repositories` doit être ajouté au chemin, car il était précédemment ajouté en interne.

```ruby
gitaly['configuration'] = {
  storage: [
    {
      name: 'default',
      path: '/mnt/nas/git-data/repositories',
    },
  ],
}
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

Il est important de noter que le répertoire parent du `path` doit également être géré par Omnibus. En suivant l'exemple ci-dessus, Omnibus doit modifier les permissions de `/mnt/nas/git-data` lors de la reconfiguration et peut stocker des données dans ce répertoire lors de l'exécution. Vous devez sélectionner un `path` approprié qui permet ce comportement.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

Pour les clients Rails et Sidekiq, si votre configuration `/etc/gitlab/gitlab.rb` est la suivante :

```ruby
git_data_dirs({
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
   }
})
```

Vous devrez redéfinir la configuration sous `gitlab_rails['repositories_storages']` à la place :

```ruby
gitlab_rails['repositories_storages'] = {
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
  }
}
```

## Stocker les données Git dans un répertoire alternatif {#store-git-data-in-an-alternative-directory}

Par défaut, les installations de packages Linux stockent les données du dépôt Git sous `/var/opt/gitlab/git-data/repositories`, et le service Gitaly écoute sur `unix:/var/opt/gitlab/gitaly/gitaly.socket`.

Pour modifier l'emplacement du répertoire,

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

   Vous pouvez également ajouter plusieurs répertoires de données Git :

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
       },
       {
         name: 'alternative',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Facultatif. Si vous avez déjà des dépôts Git existants dans `/var/opt/gitlab/git-data`, vous pouvez les déplacer vers le nouvel emplacement :
   1. Empêchez les utilisateurs d'écrire dans les dépôts pendant que vous les déplacez :

      ```shell
      sudo gitlab-ctl stop
      ```

   1. Synchronisez les dépôts vers le nouvel emplacement. Notez qu'il n'y a _pas_ de barre oblique après `repositories`, mais qu'il _y en a_ une après `git-data` :

      ```shell
      sudo rsync -av --delete /var/opt/gitlab/git-data/repositories /mnt/nas/git-data/
      ```

   1. Reconfigurez pour démarrer les processus nécessaires et corriger les permissions incorrectes :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Vérifiez la structure du répertoire dans `/mnt/nas/git-data/`. La sortie attendue doit être `repositories` :

      ```shell
      sudo ls /mnt/nas/git-data/
      ```

   1. Démarrez GitLab et vérifiez que vous pouvez parcourir les dépôts dans l'interface web :

      ```shell
      sudo gitlab-ctl start
      ```

Si vous exécutez Gitaly sur un serveur distinct, consultez [la documentation sur la configuration de Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-gitaly-clients).

Si vous ne souhaitez pas déplacer tous les dépôts, mais plutôt déplacer des projets spécifiques entre des stockages de dépôts existants, utilisez le point de terminaison [Edit Project API](https://docs.gitlab.com/api/projects/#edit-a-project) et spécifiez l'attribut `repository_storage`.

## Modifier le nom de l'utilisateur ou du groupe Git {#change-the-name-of-the-git-user-or-group}

> [!warning]
> Nous ne recommandons pas de modifier l'utilisateur ou le groupe d'une installation existante, car cela peut entraîner des effets secondaires imprévisibles.

Par défaut, les installations de packages Linux utilisent le nom d'utilisateur `git` pour la connexion à GitLab Shell via Git, la propriété des données Git elles-mêmes et la génération d'URL SSH dans l'interface web. De même, le groupe `git` est utilisé pour la propriété de groupe des données Git.

Pour modifier l'utilisateur et le groupe lors d'une nouvelle installation de package Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   user['username'] = "gitlab"
   user['group'] = "gitlab"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Si vous modifiez le nom d'utilisateur d'une installation existante, la reconfiguration ne modifie pas la propriété des répertoires imbriqués ; vous devez donc le faire manuellement.

Au minimum, vous devez modifier la propriété des répertoires de dépôts et des téléversements :

```shell
sudo chown -R gitlab:gitlab /var/opt/gitlab/git-data/repositories
sudo chown -R gitlab:gitlab /var/opt/gitlab/gitlab-rails/uploads
```

## Spécifier les identifiants numériques d'utilisateur et de groupe {#specify-numeric-user-and-group-identifiers}

Les installations de packages Linux créent des utilisateurs pour GitLab, PostgreSQL, Redis, NGINX, etc. Pour spécifier les identifiants numériques de ces utilisateurs :

1. Notez les anciens identifiants d'utilisateur et de groupe, car vous pourriez en avoir besoin ultérieurement :

   ```shell
   sudo cat /etc/passwd
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et changez les identifiants souhaités :

   ```ruby
   user['uid'] = 1234
   user['gid'] = 1234
   postgresql['uid'] = 1235
   postgresql['gid'] = 1235
   redis['uid'] = 1236
   redis['gid'] = 1236
   web_server['uid'] = 1237
   web_server['gid'] = 1237
   registry['uid'] = 1238
   registry['gid'] = 1238
   prometheus['uid'] = 1240
   prometheus['gid'] = 1240
   ```

1. Arrêtez, reconfigurez, puis démarrez GitLab :

   ```shell
   sudo gitlab-ctl stop
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl start
   ```

1. Facultatif. Si vous modifiez `user['uid']` et `user['gid']`, assurez-vous de mettre à jour l'uid/guid de tous les fichiers non gérés directement par le package Linux, par exemple les journaux :

   ```shell
   find /var/log/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/log/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   find /var/opt/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/opt/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   ```

## Désactiver la gestion des comptes d'utilisateur et de groupe {#disable-user-and-group-account-management}

Par défaut, les installations de packages Linux créent des comptes d'utilisateurs et de groupes système, et maintiennent les informations à jour. Ces comptes système exécutent divers composants du package. La plupart des utilisateurs n'ont pas besoin de modifier ce comportement. Cependant, si vos comptes système sont gérés par un autre logiciel, par exemple LDAP, vous pourriez avoir besoin de désactiver la gestion des comptes effectuée par le package GitLab.

Par défaut, les installations de packages Linux s'attendent à ce que les utilisateurs et groupes suivants existent :

| Utilisateur et groupe Linux | Requis                                | Description                                                           | Répertoire personnel par défaut       | Shell par défaut |
|----------------------|-----------------------------------------|-----------------------------------------------------------------------|------------------------------|---------------|
| `git`                | Oui                                     | Utilisateur/groupe GitLab                                                     | `/var/opt/gitlab`            | `/bin/sh`     |
| `gitlab-www`         | Oui                                     | Utilisateur/groupe du serveur web                                                 | `/var/opt/gitlab/nginx`      | `/bin/false`  |
| `gitlab-prometheus`  | Oui                                     | Utilisateur/groupe Prometheus pour la surveillance Prometheus et divers exportateurs | `/var/opt/gitlab/prometheus` | `/bin/sh`     |
| `gitlab-redis`       | Uniquement lors de l'utilisation de Redis inclus dans le package      | Utilisateur/groupe Redis pour GitLab                                           | `/var/opt/gitlab/redis`      | `/bin/false`  |
| `gitlab-psql`        | Uniquement lors de l'utilisation de PostgreSQL inclus dans le package | Utilisateur/groupe PostgreSQL                                                 | `/var/opt/gitlab/postgresql` | `/bin/sh`     |
| `gitlab-consul`      | Uniquement lors de l'utilisation de GitLab Consul           | Utilisateur/groupe GitLab Consul                                              | `/var/opt/gitlab/consul`     | `/bin/sh`     |
| `registry`           | Uniquement lors de l'utilisation de GitLab Registry         | Utilisateur/groupe GitLab Registry                                            | `/var/opt/gitlab/registry`   | `/bin/sh`     |
| `gitlab-backup`      | Uniquement lors de l'utilisation de `gitlab-backup-cli`     | Utilisateur GitLab Backup CLI                                                | `/var/opt/gitlab/backups`    | `/bin/sh`     |

Pour désactiver la gestion des comptes d'utilisateurs et de groupes :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   manage_accounts['enable'] = false
   ```

1. Facultatif. Vous pouvez également utiliser des noms d'utilisateur/groupe différents, mais vous devez alors spécifier les détails de l'utilisateur/groupe :

   ```ruby
   # GitLab
   user['username'] = "git"
   user['group'] = "git"
   user['shell'] = "/bin/sh"
   user['home'] = "/var/opt/custom-gitlab"

   # Web server
   web_server['username'] = 'webserver-gitlab'
   web_server['group'] = 'webserver-gitlab'
   web_server['shell'] = '/bin/false'
   web_server['home'] = '/var/opt/gitlab/webserver'

   # Prometheus
   prometheus['username'] = 'gitlab-prometheus'
   prometheus['group'] = 'gitlab-prometheus'
   prometheus['shell'] = '/bin/sh'
   prometheus['home'] = '/var/opt/gitlab/prometheus'

   # Redis (not needed when using external Redis)
   redis['username'] = "redis-gitlab"
   redis['group'] = "redis-gitlab"
   redis['shell'] = "/bin/false"
   redis['home'] = "/var/opt/redis-gitlab"

   # Postgresql (not needed when using external Postgresql)
   postgresql['username'] = "postgres-gitlab"
   postgresql['group'] = "postgres-gitlab"
   postgresql['shell'] = "/bin/sh"
   postgresql['home'] = "/var/opt/postgres-gitlab"

   # Consul
   consul['username'] = 'gitlab-consul'
   consul['group'] = 'gitlab-consul'
   consul['dir'] = "/var/opt/gitlab/registry"

   # Registry
   registry['username'] = "registry"
   registry['group'] = "registry"
   registry['dir'] = "/var/opt/gitlab/registry"
   registry['shell'] = "/usr/sbin/nologin"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Déplacer le répertoire personnel d'un utilisateur {#move-the-home-directory-for-a-user}

Pour l'utilisateur GitLab, nous recommandons que le répertoire personnel soit défini sur un disque local et non sur un stockage partagé tel que NFS, pour de meilleures performances. Lors de sa définition dans NFS, les requêtes Git doivent effectuer une autre requête réseau pour lire la configuration Git, ce qui augmente la latence des opérations Git.

Pour déplacer un répertoire personnel existant, les services GitLab doivent être arrêtés et une interruption de service est nécessaire :

1. Arrêtez GitLab :

   ```shell
   sudo gitlab-ctl stop
   ```

1. Arrêtez le serveur runit :

   ```shell
   sudo systemctl stop gitlab-runsvdir
   ```

1. Modifiez le répertoire personnel :

   ```shell
   sudo usermod -d /path/to/home <username>
   ```

   Si vous avez des données existantes, vous devez les copier/rsync manuellement vers le nouvel emplacement :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   user['home'] = "/var/opt/custom-gitlab"
   ```

1. Démarrez le serveur runit :

   ```shell
   sudo systemctl start gitlab-runsvdir
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Désactiver la gestion des répertoires de stockage {#disable-storage-directories-management}

Le package Linux se charge de créer tous les répertoires nécessaires avec les permissions et la propriété correctes, et de maintenir ces informations à jour.

Certains répertoires contiennent de grandes quantités de données ; dans certaines configurations, ces répertoires sont très probablement montés sur un partage NFS (ou autre).

Certains types de montages n'autorisent pas la création automatique de répertoires par l'utilisateur root (utilisateur par défaut pour la configuration initiale), par exemple NFS avec `root_squash` activé sur le partage. Pour contourner ce problème, le package Linux tente de créer ces répertoires en utilisant l'utilisateur propriétaire du répertoire.

### Désactiver la gestion du répertoire `/etc/gitlab` {#disable-the-etcgitlab-directory-management}

Si vous avez le répertoire `/etc/gitlab` monté, vous pouvez désactiver la gestion de ce répertoire :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   manage_storage_directories['manage_etc'] = false
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Désactiver la gestion du répertoire `/var/opt/gitlab` {#disable-the-varoptgitlab-directory-management}

Si vous montez tous les répertoires de stockage GitLab, chacun sur un montage séparé, vous devez désactiver complètement la gestion des répertoires de stockage.

Les installations de packages Linux s'attendent à ce que ces répertoires existent sur le système de fichiers. Il vous appartient de les créer et de définir les permissions correctes si ce paramètre est activé.

L'activation de ce paramètre empêche la création des répertoires suivants :

| Emplacement par défaut                                       | Permissions | Propriété        | Objectif |
|--------------------------------------------------------|-------------|------------------|---------|
| `/var/opt/gitlab/git-data`                             | `2770`      | `git:git`        | Contient le répertoire des dépôts |
| `/var/opt/gitlab/git-data/repositories`                | `2770`      | `git:git`        | Contient les dépôts Git |
| `/var/opt/gitlab/gitlab-rails/shared`                  | `0751`      | `git:gitlab-www` | Contient les répertoires de grands objets |
| `/var/opt/gitlab/gitlab-rails/shared/artifacts`        | `0700`      | `git:git`        | Contient les artefacts CI |
| `/var/opt/gitlab/gitlab-rails/shared/external-diffs`   | `0700`      | `git:git`        | Contient les diffs externes de merge request |
| `/var/opt/gitlab/gitlab-rails/shared/lfs-objects`      | `0700`      | `git:git`        | Contient les objets LFS |
| `/var/opt/gitlab/gitlab-rails/shared/packages`         | `0700`      | `git:git`        | Contient le dépôt de packages |
| `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy` | `0700`      | `git:git`        | Contient le proxy de dépendances |
| `/var/opt/gitlab/gitlab-rails/shared/terraform_state`  | `0700`      | `git:git`        | Contient l'état Terraform |
| `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`  | `0700`      | `git:git`        | Contient les fichiers sécurisés téléversés |
| `/var/opt/gitlab/gitlab-rails/shared/pages`            | `0750`      | `git:gitlab-www` | Contient les pages utilisateur |
| `/var/opt/gitlab/gitlab-rails/uploads`                 | `0700`      | `git:git`        | Contient les pièces jointes des utilisateurs |
| `/var/opt/gitlab/gitlab-ci/builds`                     | `0700`      | `git:git`        | Contient les journaux de build CI |
| `/var/opt/gitlab/.ssh`                                 | `0700`      | `git:git`        | Contient les clés autorisées |

Pour désactiver la gestion des répertoires de stockage :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   manage_storage_directories['enable'] = false
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Démarrer les services d'installation de packages Linux uniquement après le montage d'un système de fichiers donné {#start-linux-package-installation-services-only-after-a-given-file-system-is-mounted}

Si vous souhaitez empêcher les services d'installation de packages Linux (NGINX, Redis, Puma, etc.) de démarrer avant le montage d'un système de fichiers donné, vous pouvez définir le paramètre `high_availability['mountpoint']` :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # wait for /var/opt/gitlab to be mounted
   high_availability['mountpoint'] = '/var/opt/gitlab'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   > [!note]
   > Si le point de montage n'existe pas, GitLab échoue à se reconfigurer.

## Configurer le répertoire d'exécution {#configure-the-runtime-directory}

Lorsque la surveillance Prometheus est activée, GitLab Exporter effectue des mesures de chaque processus Puma (métriques Rails). Chaque processus Puma doit écrire un fichier de métriques dans un emplacement temporaire pour chaque requête de contrôleur. Prometheus collecte ensuite tous ces fichiers et traite leurs valeurs.

Pour éviter de créer des E/S disque, le package Linux utilise un répertoire d'exécution.

Lors de l'exécution de `reconfigure`, le package vérifie si `/run` est un montage `tmpfs`. Si ce n'est pas le cas, l'avertissement suivant s'affiche et les métriques Rails sont désactivées :

```plaintext
Runtime directory '/run' is not a tmpfs mount.
```

Pour réactiver les métriques Rails :

1. Modifiez `/etc/gitlab/gitlab.rb` pour créer un montage `tmpfs` (notez qu'il n'y a pas de `=` dans la configuration) :

   ```ruby
   runtime_dir '/path/to/tmpfs'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configurer un blocage en cas d'échec d'authentification {#configure-a-failed-authentication-ban}

Vous pouvez configurer un [blocage en cas d'échec d'authentification](https://docs.gitlab.com/security/rate_limits/#failed-authentication-ban-for-git-and-container-registry) pour Git et le registre de conteneurs. Lorsqu'un client est banni, un code d'erreur 403 est renvoyé.

Les paramètres suivants peuvent être configurés :

| Paramètre        | Description |
|----------------|-------------|
| `enabled`      | `false` par défaut. Définissez cette valeur sur `true` pour activer le blocage d'authentification Git et du registre de conteneurs. |
| `ip_whitelist` | Adresses IP à ne pas bloquer. Elles doivent être formatées sous forme de chaînes dans un tableau Ruby. Vous pouvez utiliser des IP individuelles ou la notation CIDR, par exemple `["127.0.0.1", "127.0.0.2", "127.0.0.3", "192.168.0.1/24"]`. |
| `maxretry`     | Le nombre maximum de fois qu'une requête peut être effectuée dans le temps spécifié. |
| `findtime`     | La durée maximale en secondes pendant laquelle les requêtes échouées peuvent être comptabilisées contre une IP avant qu'elle ne soit ajoutée à la liste de refus. |
| `bantime`      | La durée totale en secondes pendant laquelle une IP est bloquée. |

Pour configurer le blocage d'authentification Git et du registre de conteneurs :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['rack_attack_git_basic_auth'] = {
     'enabled' => true,
     'ip_whitelist' => ["127.0.0.1"],
     'maxretry' => 10, # Limit the number of Git HTTP authentication attempts per IP
     'findtime' => 60, # Reset the auth attempt counter per IP after 60 seconds
     'bantime' => 3600 # Ban an IP for one hour (3600s) after too many auth attempts
   }
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Désactiver le nettoyage automatique du cache lors de l'installation {#disable-automatic-cache-cleaning-during-installation}

Si vous avez une grande installation GitLab, vous ne souhaitez peut-être pas exécuter une tâche `rake cache:clear`, car cela peut prendre beaucoup de temps. Par défaut, la tâche de nettoyage du cache s'exécute automatiquement lors de la reconfiguration.

Pour désactiver le nettoyage automatique du cache lors de l'installation :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # This is an advanced feature used by large gitlab deployments where loading
   # whole RAILS env takes a lot of time.
   gitlab_rails['rake_cache_clear'] = false
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Rapport d'erreurs et journalisation avec Sentry {#error-reporting-and-logging-with-sentry}

> [!warning]
> Dans GitLab 17.0 et versions ultérieures, seules les versions 21.5.0 ou ultérieures de Sentry seront prises en charge. Si vous utilisez une version antérieure d'une instance Sentry que vous hébergez, vous devez [mettre à niveau Sentry](https://develop.sentry.dev/self-hosted/releases/) pour continuer à collecter les erreurs de vos environnements GitLab.

Sentry est un outil open source de rapport d'erreurs et de journalisation qui peut être utilisé en tant que SaaS (<https://sentry.io/welcome/>) ou [hébergé par vous-même](https://develop.sentry.dev/self-hosted/).

Pour configurer Sentry :

1. Créez un projet dans Sentry.
1. Trouvez le [Data Source Name (DSN)](https://docs.sentry.io/concepts/key-terms/dsn-explainer/) du projet que vous avez créé.
1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['sentry_enabled'] = true
   gitlab_rails['sentry_dsn'] = 'https://<public_key>@<host>/<project_id>'            # value used by the Rails SDK
   gitlab_rails['sentry_clientside_dsn'] = 'https://<public_key>@<host>/<project_id>' # value used by the Browser JavaScript SDK
   gitlab_rails['sentry_environment'] = 'production'
   ```

   L'[environnement Sentry](https://docs.sentry.io/concepts/key-terms/environments/) peut être utilisé pour suivre les erreurs et les tickets dans plusieurs environnements GitLab déployés, par exemple, lab, développement, staging et production.

1. Facultatif. Pour définir des [tags Sentry](https://docs.sentry.io/concepts/key-terms/enrich-data/) personnalisés sur chaque événement envoyé depuis un serveur particulier, la variable d'environnement `GITLAB_SENTRY_EXTRA_TAGS` peut être définie. Cette variable est un hash encodé en JSON représentant tous les tags qui doivent être transmis à Sentry pour toutes les exceptions provenant de ce serveur.

   Par exemple, en définissant :

   ```ruby
   gitlab_rails['env'] = {
     'GITLAB_SENTRY_EXTRA_TAGS' => '{"stage": "main"}'
   }
   ```

   Le tag `stage` avec la valeur `main` sera ajouté.

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Définir une URL de réseau de diffusion de contenu {#set-a-content-delivery-network-url}

Servez les ressources statiques avec un réseau de diffusion de contenu (CDN) ou un hôte de ressources en utilisant `gitlab_rails['cdn_host']`. Cela configure un [hôte de ressources Rails](https://guides.rubyonrails.org/configuring.html#config-asset-host).

Pour définir un CDN/hôte de ressources :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['cdn_host'] = 'https://mycdnsubdomain.fictional-cdn.com'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

La documentation supplémentaire pour la configuration de services courants en tant qu'hôte de ressources est suivie dans [ce ticket](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5708).

## Définir une politique de sécurité du contenu {#set-a-content-security-policy}

La définition d'une politique de sécurité du contenu (CSP) peut aider à contrecarrer les attaques de script intersite (XSS) JavaScript. Consultez [la documentation Mozilla sur les CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP) pour plus de détails.

[CSP et nonce-source avec JavaScript en ligne](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/script-src) est disponible sur GitLab.com. Il [n'est pas configuré par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/30720) sur GitLab Self-Managed.

> [!note]
> Une configuration incorrecte des règles CSP pourrait empêcher GitLab de fonctionner correctement. Avant de déployer une politique, vous pouvez également changer `report_only` en `true` pour tester la configuration.

Pour ajouter une CSP :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false
   }
   ```

   GitLab fournit automatiquement des valeurs par défaut sécurisées pour la CSP. La définition explicite de la valeur `<default_value>` pour une directive équivaut à ne pas définir de valeur et utilisera les valeurs par défaut.

   Pour ajouter une CSP personnalisée :

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false,
       directives: {
         default_src: "'none'",
         script_src: "https://example.com"
       }
   }
   ```

   Les valeurs par défaut sécurisées sont utilisées pour les directives qui ne sont pas explicitement configurées.

   Pour annuler une directive CSP, définissez une valeur de `false`.

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Définir les hôtes autorisés pour prévenir les attaques d'en-tête Host {#set-allowed-hosts-to-prevent-host-header-attacks}

Pour empêcher GitLab d'accepter un en-tête Host autre que celui prévu :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['allowed_hosts'] = ['gitlab.example.com']
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Il n'y a aucun problème de sécurité connu dans GitLab causé par la non-configuration de `allowed_hosts`, mais il est recommandé pour une défense en profondeur contre les potentielles [attaques d'en-tête HTTP Host](https://portswigger.net/web-security/host-header).

Si vous utilisez un proxy externe personnalisé tel qu'Apache, il peut être nécessaire d'ajouter l'adresse ou le nom de l'hôte local (`localhost` ou `127.0.0.1`). Vous devriez ajouter des filtres au proxy externe pour atténuer les potentielles attaques d'en-tête HTTP Host transmises via le proxy à workhorse.

```ruby
gitlab_rails['allowed_hosts'] = ['gitlab.example.com', '127.0.0.1', 'localhost']
```

## Configuration des cookies de session {#session-cookie-configuration}

Pour modifier le préfixe des valeurs de cookies de session web générées :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['session_store_session_cookie_token_prefix'] = 'custom_prefix_'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

La valeur par défaut est une chaîne vide `""`.

## Fournir une configuration sensible aux composants sans stockage en texte brut {#provide-sensitive-configuration-to-components-without-plain-text-storage}

Certains composants exposent une option `extra_config_command` dans `gitlab.rb`. Cela permet à un script externe de fournir des secrets de manière dynamique plutôt que de les lire depuis un stockage en texte brut.

Les options disponibles sont :

| Paramètre `gitlab.rb`                          | Responsabilité |
|----------------------------------------------|----------------|
| `redis['extra_config_command']`              | Fournit une configuration supplémentaire au fichier de configuration du serveur Redis. |
| `gitlab_rails['redis_extra_config_command']` | Fournit une configuration supplémentaire aux fichiers de configuration Redis utilisés par l'application GitLab Rails. (fichiers `resque.yml`, `redis.yml`, `redis.<redis_instance>.yml`) |
| `gitlab_rails['db_extra_config_command']`    | Fournit une configuration supplémentaire au fichier de configuration de la base de données utilisé par l'application GitLab Rails. (`database.yml`) |
| `gitlab_kas['extra_config_command']`         | Fournit une configuration supplémentaire au serveur d'agent GitLab pour Kubernetes (KAS). |
| `gitlab_workhorse['extra_config_command']`   | Fournit une configuration supplémentaire à GitLab Workhorse. |
| `gitlab_exporter['extra_config_command']`    | Fournit une configuration supplémentaire à GitLab Exporter. |

La valeur assignée à l'une de ces options doit être un chemin absolu vers un script exécutable qui écrit la configuration sensible dans le format requis sur STDOUT. Les composants :

1. Exécutent le script fourni.
1. Remplacent les valeurs définies par l'utilisateur et les fichiers de configuration par défaut par celles émises par le script.

### Fournir le mot de passe Redis au serveur Redis et aux composants clients {#provide-redis-password-to-redis-server-and-client-components}

À titre d'exemple, vous pouvez utiliser le script et l'extrait `gitlab.rb` ci-dessous pour spécifier le mot de passe du serveur Redis et des composants qui doivent se connecter à Redis.

> [!note]
> Lors de la spécification du mot de passe au serveur Redis, cette méthode évite uniquement à l'utilisateur d'avoir le mot de passe en texte brut dans le fichier `gitlab.rb`. Le mot de passe se retrouvera en texte brut dans le fichier de configuration du serveur Redis situé à `/var/opt/gitlab/redis/redis.conf`.

1. Enregistrez le script ci-dessous sous `/opt/generate-redis-conf`

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'json'
   require 'yaml'

   class RedisConfig
     REDIS_PASSWORD = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch Redis password

     class << self
       def server
         puts "requirepass '#{REDIS_PASSWORD}'"
         puts "masterauth '#{REDIS_PASSWORD}'"
       end

       def rails
         puts YAML.dump({
           'password' => REDIS_PASSWORD
         })
       end

       def kas
         puts YAML.dump({
           'redis' => {
             'password' => REDIS_PASSWORD
           }
         })
       end

       def workhorse
         puts JSON.dump({
           redis: {
             password: REDIS_PASSWORD
           }
         })
       end

       def gitlab_exporter
         puts YAML.dump({
           'probes' => {
             'sidekiq' => {
               'opts' => {
                 'redis_password' => REDIS_PASSWORD
               }
             }
           }
         })
       end
     end
   end

   def print_error_and_exit
     $stdout.puts "Usage: generate-redis-conf <COMPONENT>"
     $stderr.puts "Supported components are: server, rails, kas, workhorse, gitlab_exporter"

     exit 1
   end

   print_error_and_exit if ARGV.length != 1

   component = ARGV.shift
   begin
     RedisConfig.send(component.to_sym)
   rescue NoMethodError
     print_error_and_exit
   end
   ```

1. Assurez-vous que le script créé ci-dessus est exécutable :

   ```shell
   chmod +x /opt/generate-redis-conf
   ```

1. Ajoutez l'extrait ci-dessous à `/etc/gitlab/gitlab.rb` :

   ```ruby
   redis['extra_config_command'] = '/opt/generate-redis-conf server'

   gitlab_rails['redis_extra_config_command'] = '/opt/generate-redis-conf rails'
   gitlab_workhorse['extra_config_command'] = '/opt/generate-redis-conf workhorse'
   gitlab_kas['extra_config_command'] = '/opt/generate-redis-conf kas'
   gitlab_exporter['extra_config_command'] = '/opt/generate-redis-conf gitlab_exporter'
   ```

1. Exécutez `sudo gitlab-ctl reconfigure`.

### Fournir le mot de passe utilisateur PostgreSQL à GitLab Rails {#provide-the-postgresql-user-password-to-gitlab-rails}

À titre d'exemple, vous pouvez utiliser le script et la configuration ci-dessous pour fournir le mot de passe que GitLab Rails doit utiliser pour se connecter au serveur PostgreSQL.

1. Enregistrez le script ci-dessous sous `/opt/generate-db-config` :

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'yaml'

   db_password = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch DB password

   puts YAML.dump({
    'main' => {
      'password' => db_password
    },
    'ci' => {
      'password' => db_password
    }
   })
   ```

1. Assurez-vous que le script créé ci-dessus est exécutable :

   ```shell
   chmod +x /opt/generate-db-config
   ```

1. Ajoutez l'extrait ci-dessous à `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['db_extra_config_command'] = '/opt/generate-db-config'
   ```

1. Exécutez `sudo gitlab-ctl reconfigure`.

## Sujets connexes {#related-topics}

- [Désactiver l'usurpation d'identité](https://docs.gitlab.com/api/rest/authentication/#disable-impersonation)
- [Configurer la connexion LDAP](https://docs.gitlab.com/administration/auth/ldap/)
- [Authentification par carte à puce](https://docs.gitlab.com/administration/auth/smartcard/)
- [Configurer NGINX](nginx.md) pour des opérations telles que :
  - Configurer HTTPS
  - Rediriger les requêtes `HTTP` vers `HTTPS`
  - Modifier le port par défaut et les emplacements des certificats SSL
  - Définir l'adresse ou les adresses d'écoute NGINX
  - Insérer des paramètres NGINX personnalisés dans le bloc serveur GitLab
  - Insérer des paramètres personnalisés dans la configuration NGINX
  - Activer `nginx_status`
- [Utiliser un serveur web non inclus dans le package](nginx.md#use-a-non-bundled-web-server)
- [Utiliser un serveur de gestion de base de données PostgreSQL non inclus dans le package](database.md)
- [Utiliser une instance Redis non incluse dans le package](redis.md)
- [Ajouter des variables `ENV` à l'environnement d'exécution GitLab](environment-variables.md)
- [Modifier les paramètres de `gitlab.yml` et `application.yml`](gitlab.yml.md)
- [Envoyer des e-mails d'application via SMTP](smtp.md)
- [Configurer OmniAuth (connexion Google, Twitter, GitHub)](https://docs.gitlab.com/integration/omniauth/)
- [Ajuster les paramètres Puma](https://docs.gitlab.com/administration/operations/puma/)

## Dépannage {#troubleshooting}

### Dépannage des URL relatives {#relative-url-troubleshooting}

Si vous constatez des problèmes avec les ressources GitLab apparaissant comme brisées après le passage à une configuration d'URL relative (comme des images manquantes ou des composants non réactifs), veuillez ouvrir un ticket dans [GitLab](https://gitlab.com/gitlab-org/gitlab) avec le label `Frontend`.

### Erreur : `Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group]` {#error-mixlibshelloutshellcommandfailed-linux_usergitlab-user-and-group}

Lors du [déplacement du répertoire personnel d'un utilisateur](#move-the-home-directory-for-a-user), si le service runit n'est pas arrêté et que les répertoires personnels ne sont pas déplacés manuellement pour l'utilisateur, GitLab rencontrera une erreur lors de la reconfiguration :

```plaintext
account[GitLab user and group] (package::users line 28) had an error: Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/package/resources/account.rb line 51) had an error: Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '8'
---- Begin output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
STDOUT:
STDERR: usermod: user git is currently used by process 1234
---- End output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
Ran ["usermod", "-d", "/var/opt/gitlab", "git"] returned 8
```

Assurez-vous d'arrêter `runit` avant de déplacer le répertoire personnel.

### GitLab répond avec 502 après avoir modifié le nom de l'utilisateur ou du groupe Git {#gitlab-responds-with-502-after-changing-the-name-of-the-git-user-or-group}

Si vous avez modifié le [nom de l'utilisateur ou du groupe Git](#change-the-name-of-the-git-user-or-group) sur une installation existante, cela peut provoquer de nombreux effets secondaires.

Vous pouvez rechercher les erreurs liées aux fichiers inaccessibles et essayer de corriger leurs permissions :

```shell
gitlab gitlab-ctl tail -f
```
