---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Commandes de maintenance
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les commandes suivantes peuvent être exécutées après l'installation.

## Obtenir le statut du service {#get-service-status}

Exécutez `sudo gitlab-ctl status` pour voir l'état actuel et la durée de fonctionnement de chaque composant GitLab.

La sortie ressemblera à ceci :

```plaintext
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: puma: (pid 961) 7s; run: log: (pid 960) 7s
```

À titre de démonstration, la première ligne de l'exemple précédent peut être interprétée comme suit :

- `Nginx` est le nom du processus.
- `972` est l'identifiant du processus.
- NGINX fonctionne depuis 7 secondes (`7s`).
- `log` indique un [processus de journalisation svlogd](https://manpages.ubuntu.com/manpages/noble/en/man8/svlogd.8.html) attaché au processus précédent.
- `971` est l'identifiant du processus de journalisation.
- Le processus de journalisation fonctionne depuis 7 secondes (`7s`).

## Afficher la configuration {#show-configuration}

Exécutez `sudo gitlab-ctl show-config` pour afficher la configuration qui serait générée par `gitlab-ctl reconfigure`. La sortie est au format JSON et ressemblera à ceci :

```json
{
  "gitlab": {
    "gitlab_sshd": {

    },
    "gitlab_shell": {
      "secret_token": "<SECRET_TOKEN>",
      "auth_file": "/var/opt/gitlab/.ssh/authorized_keys"
    },
    "gitlab_rails": {
      "smtp_address": "smtp.example.com",
      "smtp_port": 587,
      "smtp_user_name": "user@example.com",
      "smtp_password": "<SMTP_PASSWORD>",
      "smtp_domain": "smtp.example.com",
      "smtp_authentication": "login",
      "monitoring_whitelist": [
        "127.0.0.0/8",
        "::1/128",
      ],
   ...
    }
  }
}
```

Une fois GitLab reconfiguré, vous pouvez consulter les fichiers de configuration YAML générés automatiquement dans le répertoire `/var/opt/gitlab` pour le service correspondant afin de vérifier la dernière configuration appliquée. Dans l'exemple ci-dessus, vous pouvez vérifier la configuration de `gitlab-rails` sous `/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`.

## Suivre les journaux de processus {#tail-process-logs}

Voir [Journaux sur les installations de packages Linux](../settings/logs.md).

## Démarrage et arrêt {#starting-and-stopping}

Une fois le package Linux installé et configuré, votre serveur dispose d'un processus de répertoire de service runit (`runsvdir`) en cours d'exécution, qui est démarré au démarrage via `/etc/inittab` ou la ressource Upstart `/etc/init/gitlab-runsvdir.conf`. Vous ne devriez pas avoir à gérer directement le processus `runsvdir` ; vous pouvez utiliser le frontal `gitlab-ctl` à la place.

Vous pouvez démarrer, arrêter ou redémarrer GitLab et tous ses composants avec les commandes suivantes.

```shell
# Start all GitLab components
sudo gitlab-ctl start

# Stop all GitLab components
sudo gitlab-ctl stop

# Restart all GitLab components
sudo gitlab-ctl restart

# Restart all GitLab components except given services ... (e.g. gitaly, redis)
sudo gitlab-ctl restart-except gitaly redis
```

Notez que sur un serveur monocœur, le redémarrage de Puma et Sidekiq peut prendre jusqu'à une minute. Votre instance GitLab renverra une erreur 502 jusqu'à ce que Puma soit à nouveau opérationnel.

Il est également possible de démarrer, arrêter ou redémarrer des composants individuels.

```shell
sudo gitlab-ctl restart sidekiq
```

Puma prend en charge les rechargements avec un temps d'arrêt quasi nul. Ceux-ci peuvent être déclenchés comme suit :

```shell
sudo gitlab-ctl hup puma
```

Vous devez attendre que la commande `hup` se termine. Cela peut prendre un certain temps. Laissez le nœud hors du pool et ne redémarrez pas les services sur le nœud où cette commande est invoquée tant qu'elle n'est pas terminée. Vous ne pouvez pas non plus utiliser un rechargement Puma pour mettre à jour le runtime Ruby.

Puma dispose des signaux suivants pour contrôler le comportement de l'application :

| Signal   | Puma                                                                |
| -------- | ------                                                              |
| `HUP`    | rouvre les fichiers journaux définis, ou arrête le processus pour forcer le redémarrage      |
| `INT`    | arrête le traitement des requêtes de manière progressive                                |
| `USR1`   | redémarre les workers en phases, un redémarrage progressif, sans rechargement de la configuration |
| `USR2`   | redémarre les workers et recharge la configuration                                   |
| `QUIT`   | quitte le processus principal                                               |

Pour Puma, `gitlab-ctl hup puma` enverra une séquence de signaux `SIGINT` et `SIGTERM` (si le processus ne redémarre pas). Puma cesse d'accepter de nouvelles connexions dès la réception de `SIGINT`. Il termine toutes les requêtes en cours. Ensuite, `runit` redémarre le service.

## Invocation des tâches Rake {#invoking-rake-tasks}

Pour invoquer une tâche Rake GitLab, utilisez `gitlab-rake`. Par exemple :

```shell
sudo gitlab-rake gitlab:check
```

Omettez `sudo` si vous êtes l'utilisateur `git`.

Contrairement à une installation GitLab traditionnelle, il n'est pas nécessaire de changer l'utilisateur ou la variable d'environnement `RAILS_ENV` ; ceci est pris en charge par le script wrapper `gitlab-rake`.

## Démarrer une session de console Rails {#starting-a-rails-console-session}

Pour plus d'informations, voir [Console Rails](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session).

## Démarrer une session superutilisateur PostgreSQL `psql` {#starting-a-postgresql-superuser-psql-session}

Si vous avez besoin d'un accès superutilisateur au service PostgreSQL intégré, vous pouvez utiliser la commande `gitlab-psql`. Elle accepte les mêmes arguments que la commande `psql` habituelle.

```shell
# Superuser psql access to GitLab's database
sudo gitlab-psql -d gitlabhq_production
```

Cela ne fonctionnera qu'après avoir exécuté `gitlab-ctl reconfigure` au moins une fois. La commande `gitlab-psql` ne peut pas être utilisée pour se connecter à un serveur PostgreSQL distant, ni pour se connecter à un serveur PostgreSQL local non inclus dans le package Linux.

### Démarrer une session superutilisateur PostgreSQL `psql` dans la base de données de suivi Geo {#starting-a-postgresql-superuser-psql-session-in-geo-tracking-database}

Similaire à la commande précédente, si vous avez besoin d'un accès superutilisateur à la base de données de suivi Geo intégrée (`geo-postgresql`), vous pouvez utiliser `gitlab-geo-psql`. Elle accepte les mêmes arguments que la commande `psql` habituelle. Pour la haute disponibilité, consultez les informations sur les arguments nécessaires dans [Vérification de la configuration](https://docs.gitlab.com/administration/geo/replication/multiple_servers/).

```shell
# Superuser psql access to GitLab's Geo tracking database
sudo gitlab-geo-psql -d gitlabhq_geo_production
```

## Récupération de place du registre de conteneurs {#container-registry-garbage-collection}

Le registre de conteneurs peut utiliser des quantités considérables d'espace disque. Pour libérer les couches inutilisées, le registre inclut une [commande de récupération de place](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-garbage-collection).

## Restreindre la connexion des utilisateurs à GitLab {#restrict-users-from-logging-into-gitlab}

Si vous avez besoin de restreindre temporairement la connexion des utilisateurs à GitLab, vous pouvez utiliser `sudo gitlab-ctl deploy-page up`. Lorsqu'un utilisateur accède à votre URL GitLab, une page `Deploy in progress` arbitraire lui sera affichée.

Pour supprimer la page, il vous suffit d'exécuter `sudo gitlab-ctl deploy-page down`. Vous pouvez également vérifier le statut de la page de déploiement avec `sudo gitlab-ctl deploy-page status`.

À titre d'information, si vous souhaitez restreindre la connexion à GitLab et les modifications apportées aux projets, vous pouvez [définir les projets en lecture seule](https://docs.gitlab.com/administration/read_only_gitlab/#make-the-repositories-read-only), puis afficher la page `Deploy in progress`.

## Rotation du fichier de secrets {#rotate-the-secrets-file}

Si nécessaire pour des raisons de sécurité, vous pouvez effectuer la rotation du fichier de secrets `/etc/gitlab/gitlab-secrets.json`. Dans ce fichier :

- Ne procédez pas à la rotation des secrets `gitlab_rails` car il contient les clés de chiffrement de la base de données. Si ce secret est changé, vous observez le même comportement que [lorsque le fichier de secrets est perdu](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost).
- Vous pouvez effectuer la rotation de tous les autres secrets.

Si votre environnement GitLab comporte plusieurs nœuds, choisissez l'un de vos nœuds Rails pour effectuer les étapes initiales.

Pour effectuer la rotation des secrets :

1. [Vérifiez que les valeurs de la base de données peuvent être déchiffrées](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets) et notez les erreurs de déchiffrement affichées, ou résolvez-les avant de continuer.

1. Recommandé. Extrayez vos secrets actuels pour `gitlab_rails`. Enregistrez la sortie car vous en aurez besoin ultérieurement :

   ```shell
   sudo grep "secret_key_base\|db_key_base\|otp_key_base\|encrypted_settings_key_base\|openid_connect_signing_key\|active_record_encryption_primary_key\|active_record_encryption_deterministic_key\|active_record_encryption_key_derivation_salt" /etc/gitlab/gitlab-secrets.json
   ```

1. Déplacez votre fichier de secrets actuel vers un emplacement différent :

   ```shell
   sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
   ```

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation). GitLab générera alors un nouveau fichier `/etc/gitlab/gitlab-secrets.json` avec de nouvelles valeurs de secrets.

1. Si vous avez extrait les secrets précédents pour `gitlab_rails`, modifiez le nouveau fichier `/etc/gitlab/gitlab-secrets.json` et remplacez les paires clé/valeur sous `gitlab_rails` par les secrets précédemment obtenus.

1. [Reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) à nouveau afin que les modifications apportées au fichier de secrets soient appliquées.

1. [Redémarrez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation) pour vous assurer que tous les services utilisent les nouveaux secrets.

1. Si votre environnement GitLab comporte plusieurs nœuds, vous devez copier les secrets sur tous vos autres nœuds :

   1. Sur tous les autres nœuds, déplacez votre fichier de secrets actuel vers un emplacement différent :

      ```shell
      sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
      ```

   1. Copiez le nouveau fichier `/etc/gitlab/gitlab-secrets.json` depuis votre nœud Rails vers tous vos autres nœuds GitLab.

   1. Sur tous les autres nœuds, [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) sur chaque nœud.

   1. Sur tous les autres nœuds, [redémarrez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation) sur chaque nœud pour vous assurer que tous les services utilisent les nouveaux secrets.

   1. Sur tous les nœuds, effectuez une vérification par somme de contrôle sur le fichier `/etc/gitlab/gitlab-secrets.json` pour confirmer que les secrets correspondent :

      ```shell
      sudo md5sum /etc/gitlab/gitlab-secrets.json
      ```

1. [Vérifiez que les valeurs de la base de données peuvent être déchiffrées](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets). La sortie doit correspondre à l'exécution précédente.
1. Confirmez que GitLab fonctionne comme prévu. Si c'est le cas, il devrait être sûr de supprimer les anciens secrets.

## Activer la complétion bash pour `gitlab-ctl` {#enable-bash-completion-for-gitlab-ctl}

Le package Linux inclut un script de complétion bash pour la commande `gitlab-ctl`. Pour l'activer, sourcez le script de complétion dans votre fichier de configuration du shell.

Le script de complétion est situé à `/opt/gitlab/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion`.

Pour activer la complétion bash :

1. Ajoutez la ligne suivante à votre fichier de configuration du shell (`.bashrc`, `.bash_profile`, ou équivalent) :

   ```shell
   source /opt/gitlab/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion
   ```

1. Rechargez votre configuration du shell :

   ```shell
   source ~/.bashrc
   ```

Une fois activée, vous pouvez utiliser la complétion par tabulation avec les commandes `gitlab-ctl` :

```shell
gitlab-ctl <TAB>
```

Le script de complétion nécessite que le package `bash-completion` soit installé sur votre système. Si vous ne l'avez pas installé, vous pouvez l'installer à l'aide du gestionnaire de packages de votre système :

- Debian/Ubuntu : `sudo apt-get install bash-completion`
- RHEL/CentOS : `sudo yum install bash-completion`

## Dépréciations {#deprecations}

Exécutez `sudo gitlab-ctl check-config` pour vérifier dans votre configuration Omnibus les indicateurs à supprimer dans une future version de GitLab.

La commande prend en charge les arguments suivants :

- `--version <Version>` : La version cible de GitLab par rapport à laquelle vous souhaitez vérifier votre configuration.
- `--no-fail` : Pour ne pas quitter avec un code d'échec même si des dépréciations/suppressions sont trouvées.

Lorsque vous mettez à niveau GitLab, cette vérification de configuration s'exécute automatiquement. Si vous préférez ignorer cette vérification lors des mises à niveau, créez un fichier à `/etc/gitlab/skip-fail-config-check`.
