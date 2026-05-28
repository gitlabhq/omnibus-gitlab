---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Convertir une installation compilée manuellement en installation via un package Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous avez installé GitLab en utilisant la méthode d'installation compilée manuellement, vous pouvez convertir votre instance en instance de package Linux.

Lors de la conversion d'une installation compilée manuellement :

- Vous devez convertir vers la même version exacte de GitLab.
- Vous devez [configurer les paramètres dans `/etc/gitlab/gitlab.rb`](../settings/configuration.md) car les paramètres des fichiers tels que `gitlab.yml`, `puma.rb` et `smtp_settings.rb` sont perdus.

> [!warning]
> La conversion depuis des installations compilées manuellement n'a pas été testée par GitLab.

Pour convertir votre installation compilée manuellement en installation via un package Linux :

1. Créez une sauvegarde de votre installation compilée manuellement actuelle :

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
   ```

1. [Installez GitLab à l'aide d'un package Linux](https://about.gitlab.com/install/).
1. Copiez le fichier de sauvegarde dans le répertoire `/var/opt/gitlab/backups/` du nouveau serveur.
1. Restaurez la sauvegarde dans la nouvelle installation ([instructions détaillées](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)) :

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=<FILE_NAME>
   ```

   La restauration prend quelques minutes selon la taille de votre base de données et de vos données Git.

1. Comme tous les paramètres sont stockés dans `/etc/gitlab/gitlab.rb` dans les installations via package Linux, vous devez reconfigurer la nouvelle installation. Les paramètres individuels doivent être déplacés manuellement depuis les fichiers d'installation compilée manuellement tels que `gitlab.yml`, `puma.rb` et `smtp_settings.rb`. Pour toutes les options disponibles, consultez le [modèle `gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).
1. Copiez les secrets de l'ancienne installation compilée manuellement vers la nouvelle installation via package Linux :
   1. Restaurez les secrets liés à Rails. Copiez les valeurs de `db_key_base`, `secret_key_base`, `otp_key_base`, `encrypted_settings_key_base`, `openid_connect_signing_key` et `active_record_encryption` depuis `/home/git/gitlab/config/secrets.yml` (installation compilée manuellement) vers les équivalents dans `/etc/gitlab/gitlab-secrets.json` (installation via package Linux).
   1. Copiez le contenu de `/home/git/gitlab-shell/.gitlab_shell_secret` (installation compilée manuellement) vers `secret_token` dans `/etc/gitlab/gitlab-secrets.json` (installation via package Linux). Cela ressemble à ceci :

       ```json
       {
         "gitlab_workhorse": {
           "secret_token": "..."
         },
         "gitlab_shell": {
           "secret_token": "..."
         },
         "gitlab_rails": {
           "secret_key_base": "...",
           "db_key_base": "...",
           "otp_key_base": "...",
           "encrypted_settings_key_base": "...",
           "openid_connect_signing_key": "...",
           "active_record_encryption_primary_key": [ "..."],
           "active_record_encryption_deterministic_key": ["..."],
           "active_record_encryption_key_derivation_salt": "...",
         }
         ...
       }
       ```

1. Reconfigurez GitLab pour appliquer les modifications :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Si vous avez migré `/home/git/gitlab-shell/.gitlab_shell_secret`, vous [devez redémarrer Gitaly](https://gitlab.com/gitlab-org/gitaly/-/issues/3837) :

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

## Convertir un PostgreSQL externe en installation via package Linux à l'aide d'une sauvegarde {#convert-an-external-postgresql-to-a-linux-package-installation-by-using-a-backup}

Vous pouvez convertir une [installation PostgreSQL externe](https://docs.gitlab.com/administration/postgresql/external/) en installation PostgreSQL via package Linux à l'aide d'une sauvegarde. Vous devez utiliser la même version de GitLab lors de cette opération.

Pour convertir une installation PostgreSQL externe en installation PostgreSQL via package Linux à l'aide d'une sauvegarde :

1. [Créer une sauvegarde depuis l'installation sans package Linux](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)
1. [Restauration de la sauvegarde dans l'installation via package Linux](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations).
1. Exécutez la tâche `check` :

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. Si vous recevez une erreur similaire à `No such file or directory @ realpath_rec - /home/git`, exécutez :

   ```shell
   find . -lname /home/git/gitlab-shell/hooks -exec sh -c 'ln -snf /opt/gitlab/embedded/service/gitlab-shell/hooks $0' {} \;
   ```

Cela suppose que `gitlab-shell` se trouve dans `/home/git`.

## Convertir un PostgreSQL externe en installation via package Linux en place {#convert-an-external-postgresql-to-a-linux-package-installation-in-place}

Vous pouvez convertir une [installation PostgreSQL externe](https://docs.gitlab.com/administration/postgresql/external/) en installation PostgreSQL via package Linux en place.

Ces instructions supposent :

- Vous utilisez PostgreSQL sur Ubuntu.
- Vous disposez d'un package Linux correspondant à votre version actuelle de GitLab.
- Votre installation compilée manuellement de GitLab utilise tous les chemins et utilisateurs par défaut.
- Le répertoire personnel existant de l'utilisateur Git (`/home/git`) sera modifié en `/var/opt/gitlab`.

Pour convertir une installation PostgreSQL externe en installation PostgreSQL via package Linux en place :

1. Arrêtez et désactivez GitLab, Redis et NGINX :

   ```shell
   # Ubuntu
   sudo service gitlab stop
   sudo update-rc.d gitlab disable

   sudo service nginx stop
   sudo update-rc.d nginx disable

   sudo service redis-server stop
   sudo update-rc.d redis-server disable
   ```

1. Si vous utilisez un système de gestion de configuration pour gérer GitLab sur votre serveur, désactivez GitLab et ses services associés à cet endroit.
1. Créez un fichier `gitlab.rb` pour votre nouvelle configuration :

   ```shell
   sudo mkdir /etc/gitlab
   sudo tee -a /etc/gitlab/gitlab.rb <<'EOF'
   # Use your own GitLab URL here
   external_url 'http://gitlab.example.com'

   # We assume your repositories are in /home/git/repositories (default for source installs) and that Gitaly
   # listens on a socket at /home/git/gitlab/tmp/sockets/private/gitaly.socket
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/home/git/repositories'
       }
     ]
   }
   gitlab_rails['repositories_storages'] = {
     default: {
       gitaly_address: '/home/git/gitlab/tmp/sockets/private/gitaly.socket'
     }
   }

   # Re-use the PostgreSQL that is already running on your system
   postgresql['enable'] = false
   # This db_host setting is for Debian PostgreSQL packages
   gitlab_rails['db_host'] = '/var/run/postgresql/'
   gitlab_rails['db_port'] = 5432
   # We assume you called the GitLab DB user 'git'
   gitlab_rails['db_username'] = 'git'
   EOF
   ```

1. Installez maintenant le package Linux et reconfigurez l'installation :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Étant donné que l'exécution de `gitlab-ctl reconfigure` a modifié le répertoire personnel de l'utilisateur Git et qu'OpenSSH ne peut plus trouver son fichier `authorized_keys`, reconstruisez le fichier des clés :

   ```shell
   sudo gitlab-rake gitlab:shell:setup
   ```

   Vous devriez maintenant avoir accès à votre serveur GitLab via HTTP et SSH avec les dépôts et les utilisateurs qui s'y trouvaient auparavant.

1. Si vous pouvez vous connecter à l'interface web de GitLab, redémarrez votre serveur pour vous assurer qu'aucun des anciens services n'interfère avec l'installation via package Linux.
1. Si vous utilisez des fonctionnalités spéciales telles que LDAP, vous devez placer vos paramètres dans `gitlab.rb`. Pour plus d'informations, consultez la [documentation des paramètres](../settings/_index.md).
