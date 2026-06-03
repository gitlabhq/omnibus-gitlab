---
stage: GitLab Delivery
group: Build, Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'installation du package Linux"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Utilisez cette page pour en savoir plus sur les problèmes courants que les utilisateurs peuvent rencontrer lors de l'installation de packages Linux.

## Incompatibilité de somme de hachage lors du téléchargement de packages {#hash-sum-mismatch-when-downloading-packages}

`apt-get install` génère une sortie similaire à :

```plaintext
E: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/pool/trusty/main/g/gitlab-ce/gitlab-ce_8.1.0-ce.0_amd64.deb  Hash Sum mismatch
```

Exécutez la commande suivante pour résoudre ce problème :

```shell
sudo rm -rf /var/lib/apt/lists/partial/*
sudo apt-get update
sudo apt-get clean
```

Une autre solution consiste à télécharger le package manuellement en sélectionnant le package approprié depuis le dépôt [des packages CE](https://packages.gitlab.com/gitlab/gitlab-ce) ou [des packages EE](https://packages.gitlab.com/gitlab/gitlab-ee) :

```shell
curl -LJO "https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/gitlab-ce_8.1.0-ce.0_amd64.deb/download"
dpkg -i gitlab-ce_8.1.0-ce.0_amd64.deb
```

## L'installation sur les plateformes openSUSE et SLES signale une signature de clé inconnue {#installation-on-opensuse-and-sles-platforms-warns-about-unknown-key-signature}

Les packages Linux sont [signés avec des clés GPG](update/package_signatures.md) en plus des dépôts de packages qui fournissent des métadonnées signées. Cela garantit l'authenticité et l'intégrité des packages distribués aux utilisateurs. Cependant, le gestionnaire de packages utilisé dans les systèmes d'exploitation openSUSE et SLES peut parfois émettre de faux avertissements concernant ces signatures, similaires à :

```plaintext
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no):
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no): yes
```

Il s'agit d'un bogue connu avec zypper, qui ignore le mot-clé `gpgkey` dans le fichier de configuration du dépôt. Les utilisateurs devront accepter manuellement l'installation du package lorsqu'ils y sont invités.

Ainsi, sur les systèmes openSUSE ou SLES, si un tel avertissement s'affiche, il est sans danger de poursuivre l'installation.

## apt/yum se plaint des signatures GPG {#aptyum-complains-about-gpg-signatures}

Vous avez déjà des dépôts GitLab configurés et avez exécuté `apt-get update`, `apt-get install` ou `yum install`, et avez vu des erreurs semblables aux suivantes :

```plaintext
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
```

ou

```plaintext
https://packages.gitlab.com/gitlab/gitlab-ee/el/7/x86_64/repodata/repomd.xml: [Errno -1] repomd.xml signature could not be verified for gitlab-ee
```

Cette erreur signifie généralement que vous ne disposez pas des clés publiques actuellement utilisées pour signer les métadonnées du dépôt dans votre trousseau de clés. GitLab fait périodiquement tourner les clés GPG utilisées pour signer les métadonnées des dépôts apt et yum. Pour plus de détails sur les clés actuelles et précédentes, consultez [les signatures de packages](update/package_signatures.md). Pour corriger cette erreur, suivez les [étapes permettant de récupérer la nouvelle clé](update/package_signatures.md#fetch-the-latest-repository-signing-key).

## Reconfigure affiche une erreur : `NoMethodError - undefined method '[]=' for nil:NilClass` {#reconfigure-shows-an-error-nomethoderror---undefined-method--for-nilnilclass}

Vous avez exécuté `sudo gitlab-ctl reconfigure` ou la mise à niveau du package a déclenché la reconfiguration, ce qui a produit une erreur similaire à :

```plaintext
 ================================================================================
 Recipe Compile Error in /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb
 ================================================================================

NoMethodError
-------------
undefined method '[]=' for nil:NilClass

Cookbook Trace:
---------------
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/config.rb:21:in 'from_file'
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb:26:in 'from_file'

Relevant File Content:
```

Cette erreur est générée lorsque le fichier de configuration `/etc/gitlab/gitlab.rb` contient une configuration invalide ou non prise en charge. Vérifiez qu'il n'y a pas de fautes de frappe ou que le fichier de configuration ne contient pas de configuration obsolète.

Vous pouvez vérifier la dernière configuration disponible en utilisant `sudo gitlab-ctl diff-config` ou consulter le dernier [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

## GitLab est inaccessible dans mon navigateur {#gitlab-is-unreachable-in-my-browser}

Essayez de [spécifier](settings/configuration.md#configure-the-external-url-for-gitlab) une `external_url` dans `/etc/gitlab/gitlab.rb`. Vérifiez également vos paramètres de pare-feu ; le port 80 (HTTP) ou 443 (HTTPS) est peut-être fermé sur votre serveur GitLab.

Notez que la spécification de `external_url` pour GitLab, ou tout autre service intégré (comme le registre), ne suit pas le format `key=value` suivi par les autres parties de `gitlab.rb`. Assurez-vous de les définir dans le format suivant :

```ruby
external_url "https://gitlab.example.com"
registry_external_url "https://registry.example.com"
```

> [!note]
> N'ajoutez pas le signe égal (`=`) entre `external_url` et la valeur.

## Les e-mails ne sont pas distribués {#emails-are-not-being-delivered}

Pour tester la distribution d'e-mails, vous pouvez créer un nouveau compte GitLab pour une adresse e-mail qui n'est pas encore utilisée dans votre instance GitLab.

Si nécessaire, vous pouvez modifier le champ « De » des e-mails envoyés par GitLab avec le paramètre suivant dans `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.

## Les ports TCP pour les services GitLab sont déjà utilisés {#tcp-ports-for-gitlab-services-are-already-taken}

Par défaut, Puma écoute sur l'adresse TCP 127.0.0.1:8080. NGINX écoute sur le port 80 (HTTP) et/ou 443 (HTTPS) sur toutes les interfaces.

Les ports de Redis, PostgreSQL et Puma peuvent être remplacés dans `/etc/gitlab/gitlab.rb` comme suit :

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
puma['port'] = 3456
```

Pour les modifications du port NGINX, consultez [Définition du port d'écoute NGINX](settings/nginx.md#set-the-nginx-listen-port).

## L'utilisateur Git n'a pas accès à SSH {#git-user-does-not-have-ssh-access}

### Systèmes avec SELinux activé {#selinux-enabled-systems}

Sur les systèmes avec SELinux activé, le répertoire `.ssh` de l'utilisateur Git ou son contenu peut avoir son contexte de sécurité altéré. Vous pouvez corriger cela en exécutant `sudo
gitlab-ctl reconfigure`, qui définit le contexte de sécurité `gitlab_shell_t` sur `/var/opt/gitlab/.ssh`.

Pour améliorer ce comportement, nous définissons le contexte de manière permanente en utilisant `semanage`. La dépendance d'exécution `policycoreutils-python` a été ajoutée au package RPM pour les systèmes d'exploitation basés sur RHEL afin de s'assurer que la commande `semanage` est disponible.

#### Diagnostiquer et résoudre les problèmes SELinux {#diagnose-and-resolve-selinux-issues}

Les packages Linux détectent les changements de chemin par défaut dans `/etc/gitlab/gitlab.rb` et doivent appliquer les contextes de fichier corrects.

> [!note]
> Dans GitLab 16.10 et versions ultérieures, les administrateurs peuvent essayer `gitlab-ctl apply-sepolicy` pour corriger automatiquement les problèmes SELinux. Consultez `gitlab-ctl apply-sepolicy --help` pour les options d'exécution.

Pour les installations utilisant une configuration de chemin de données personnalisé, l'administrateur peut avoir à résoudre manuellement les problèmes SELinux.

Les chemins de données peuvent être modifiés via `gitlab.rb`, cependant, un scénario courant force l'utilisation de chemins `symlink`. Les administrateurs doivent être prudents, car les chemins `symlink` ne sont pas pris en charge pour tous les scénarios, comme les [chemins de données Gitaly](settings/configuration.md#store-git-data-in-an-alternative-directory).

Par exemple, si `/data/gitlab` a remplacé `/var/opt/gitlab` comme répertoire de données de base, ce qui suit corrige le contexte de sécurité :

```shell
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/authorized_keys
sudo restorecon -Rv /data/gitlab/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-shell/config.yml
sudo restorecon -Rv /data/gitlab/gitlab-shell/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-rails/etc/gitlab_shell_secret
sudo restorecon -Rv /data/gitlab/gitlab-rails/
sudo semanage fcontext --list | grep /data/gitlab/
```

Une fois les politiques appliquées, vous pouvez vérifier que l'accès SSH fonctionne en obtenant le message de bienvenue :

```shell
ssh -T git@gitlab-hostname
```

### Tous les systèmes {#all-systems}

L'utilisateur Git est créé, par défaut, avec un mot de passe verrouillé, indiqué par `'!'` dans /etc/shadow. Sauf si « UsePam yes » est activé, le démon OpenSSH empêche l'utilisateur Git de s'authentifier même avec des clés SSH. Une solution sécurisée alternative consiste à déverrouiller le mot de passe en remplaçant `'!'` par `'*'` dans `/etc/shadow`. L'utilisateur Git ne peut toujours pas modifier le mot de passe car il s'exécute dans un shell restreint et la commande `passwd` pour les non-superutilisateurs nécessite la saisie du mot de passe actuel avant un nouveau mot de passe. L'utilisateur ne peut pas saisir un mot de passe correspondant à `'*'`, ce qui signifie que le compte continue de ne pas avoir de mot de passe.

Gardez à l'esprit que l'utilisateur Git doit avoir accès au système, alors vérifiez vos paramètres de sécurité dans `/etc/security/access.conf` et assurez-vous que l'utilisateur Git n'est pas bloqué.

## Erreur : `FATAL: could not create shared memory segment: Cannot allocate memory` {#error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory}

L'instance PostgreSQL packagée tente d'allouer 25 % de la mémoire totale en tant que mémoire partagée. Sur certains serveurs Linux (virtuels), la mémoire partagée disponible est insuffisante, ce qui empêche PostgreSQL de démarrer. Dans `/var/log/gitlab/postgresql/current` :

```plaintext
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

Vous pouvez réduire manuellement la quantité de mémoire partagée que PostgreSQL tente d'allouer dans `/etc/gitlab/gitlab.rb` :

```ruby
postgresql['shared_buffers'] = "100MB"
```

Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.

## Erreur : `FATAL: could not open shared memory segment "/PostgreSQL.XXXXXXXXXX": Permission denied` {#error-fatal-could-not-open-shared-memory-segment-postgresqlxxxxxxxxxx-permission-denied}

Par défaut, PostgreSQL tente de détecter le type de mémoire partagée à utiliser. Si vous n'avez pas de mémoire partagée activée, vous pourriez voir cette erreur dans `/var/log/gitlab/postgresql/current`. Pour résoudre ce problème, vous pouvez désactiver la détection de mémoire partagée de PostgreSQL. Définissez la valeur suivante dans `/etc/gitlab/gitlab.rb` :

```ruby
postgresql['dynamic_shared_memory_type'] = 'none'
```

Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.

## Erreur : `FATAL: remaining connection slots are reserved for non-replication superuser connections` {#error-fatal-remaining-connection-slots-are-reserved-for-non-replication-superuser-connections}

PostgreSQL dispose d'un paramètre pour le nombre maximal de connexions simultanées au serveur de base de données. La limite par défaut est de 400. Si vous voyez cette erreur, cela signifie que votre instance GitLab tente de dépasser cette limite sur le nombre de connexions simultanées.

Pour vérifier les connexions maximales et les connexions disponibles :

1. Ouvrez une console de base de données PostgreSQL :

   ```shell
   sudo gitlab-psql
   ```

1. Exécutez la requête suivante dans la console de base de données :

   ```sql
   SELECT
     (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections,
     COUNT(*) AS current_connections,
     COUNT(*) FILTER (WHERE state = 'active') AS active_connections,
     ((SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - COUNT(*)) AS remaining_connections
   FROM pg_stat_activity;
   ```

Pour résoudre ce problème, vous avez deux options :

- Soit augmenter la valeur des connexions max :

  1. Modifiez `/etc/gitlab/gitlab.rb` :

     ```ruby
     postgresql['max_connections'] = 600
     ```

  1. Reconfigurer GitLab :

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. Redémarrer GitLab :

     ```shell
     sudo gitlab-ctl restart
     ```

- Ou, vous pouvez envisager [d'utiliser PgBouncer](https://docs.gitlab.com/administration/postgresql/pgbouncer/), qui est un pooler de connexions pour PostgreSQL.

## Reconfigure se plaint de la version GLIBC {#reconfigure-complains-about-the-glibc-version}

```shell
$ gitlab-ctl reconfigure

/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

Cela peut se produire si le package Linux que vous avez installé a été compilé pour une version d'OS différente de celle de votre serveur. Vérifiez que vous avez téléchargé et installé le package Linux correct pour votre système d'exploitation.

## Reconfigure échoue à créer l'utilisateur Git {#reconfigure-fails-to-create-the-git-user}

Cela peut se produire si vous exécutez `sudo gitlab-ctl reconfigure` en tant qu'utilisateur Git. Passez à un autre utilisateur.

Plus important encore : n'accordez pas les droits sudo à l'utilisateur Git ni à aucun autre utilisateur utilisé par le package Linux. Accorder des privilèges inutiles à un utilisateur système affaiblit la sécurité de votre système.

## Échec de la modification des paramètres du noyau avec sysctl {#failed-to-modify-kernel-parameters-with-sysctl}

Si sysctl ne peut pas modifier les paramètres du noyau, vous pourriez obtenir une erreur avec la trace de pile suivante :

```plaintext
 * execute[sysctl] action run
================================================================================
Error executing action `run` on resource 'execute[sysctl]'
================================================================================


Mixlib::ShellOut::ShellCommandFailed
------------------------------------
Expected process to exit with [0], but received '255'
---- Begin output of /sbin/sysctl -p /etc/sysctl.conf ----
```

Cela est peu probable avec des machines non virtualisées, mais sur un VPS avec une virtualisation telle qu'openVZ, le conteneur peut ne pas avoir le module requis activé ou le conteneur n'a pas accès aux paramètres du noyau.

Essayez d'[activer le module](https://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error) sur lequel sysctl a échoué.

Il existe un contournement signalé décrit dans [ce ticket](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/361) qui nécessite de modifier la recette interne de GitLab en fournissant le commutateur qui ignore les échecs. Ignorer les erreurs peut avoir des effets secondaires inattendus sur les performances de votre serveur GitLab, il n'est donc pas recommandé de le faire.

Une autre variante de cette erreur signale que le système de fichiers est en lecture seule et affiche la trace de pile suivante :

```plaintext
 * execute[load sysctl conf] action run
    [execute] sysctl: setting key "kernel.shmall": Read-only file system
              sysctl: setting key "kernel.shmmax": Read-only file system

    ================================================================================
    Error executing action `run` on resource 'execute[load sysctl conf]'
    ================================================================================

    Mixlib::ShellOut::ShellCommandFailed
    ------------------------------------
    Expected process to exit with [0], but received '255'
    ---- Begin output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    STDOUT:
    STDERR: sysctl: setting key "kernel.shmall": Read-only file system
    sysctl: setting key "kernel.shmmax": Read-only file system
    ---- End output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    Ran cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - returned 255
```

Cette erreur est également signalée comme se produisant uniquement dans des machines virtuelles, et la solution recommandée est de définir les valeurs dans l'hôte. Les valeurs nécessaires pour GitLab se trouvent dans le fichier `/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf` dans la machine virtuelle. Après avoir défini ces valeurs dans le fichier `/etc/sysctl.conf` sur le système d'exploitation hôte, exécutez `cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -` sur l'hôte. Essayez ensuite d'exécuter `gitlab-ctl reconfigure` à l'intérieur de la machine virtuelle. Il devrait détecter que le noyau fonctionne déjà avec les paramètres nécessaires et ne pas générer d'erreurs.

Vous devrez peut-être répéter ce processus pour d'autres lignes. Par exemple, reconfigure échoue trois fois, après avoir ajouté quelque chose comme ceci à `/etc/sysctl.conf` :

```plaintext
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 2048
kernel.shmmax = 17179869184
```

Il peut être plus facile de regarder la ligne dans la sortie Chef que de trouver le fichier (car le fichier est différent pour chaque erreur). Consultez la dernière ligne de cet extrait.

```plaintext
* file[create /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf kernel.shmall] action create
  - create new file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf
  - update content in file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf from none to 6d765d
  --- /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf 2017-11-28 19:09:46.864364952 +0000
  +++ /opt/gitlab/embedded/etc/.chef-90-omnibus-gitlab-kernel.shmall.conf kernel.shmall20171128-13622-sduqoj 2017-11-28 19:09:46.864364952 +0000
  @@ -1 +1,2 @@
  +kernel.shmall = 4194304
```

## Je ne peux pas installer GitLab sans accès root {#i-am-unable-to-install-gitlab-without-root-access}

Les gens demandent parfois s'ils peuvent installer GitLab sans accès root. Cela pose plusieurs problèmes.

### Installation de `.deb` ou `.rpm` {#installing-the-deb-or-rpm}

À notre connaissance, il n'existe pas de moyen simple d'installer des packages Debian ou RPM en tant qu'utilisateur non privilégié. Vous ne pouvez pas installer les RPM du package Linux car le processus de compilation ne crée pas de RPM sources.

### Hébergement sans contrainte sur le port `80` et `443` {#hassle-free-hosting-on-port-80-and-443}

La méthode la plus courante pour déployer GitLab consiste à avoir un serveur web (NGINX/Apache) fonctionnant sur le même serveur que GitLab, avec le serveur web à l'écoute sur un port TCP privilégié (inférieur à 1024). Dans les packages Linux, nous offrons cette commodité en intégrant un service NGINX automatiquement configuré qui doit exécuter son processus maître en tant que root pour ouvrir les ports `80` et `443`.

Si cela pose un problème, les administrateurs qui installent GitLab peuvent désactiver le service NGINX intégré, mais cela leur incombe de maintenir la configuration NGINX en accord avec GitLab lors des mises à jour de l'application.

### Isolation entre les services {#isolation-between-services}

Les services intégrés dans les packages Linux (GitLab lui-même, NGINX, PostgreSQL et Redis) sont isolés les uns des autres à l'aide de comptes d'utilisateurs Unix. La création et la gestion de ces comptes d'utilisateurs nécessitent un accès root. Par défaut, les packages Linux créent les comptes Unix requis lors de l'exécution de `gitlab-ctl reconfigure`, mais ce comportement peut être [désactivé](settings/configuration.md#disable-user-and-group-account-management).

### Optimisation du système d'exploitation pour de meilleures performances {#tweaking-the-operating-system-for-better-performance}

Lors de l'exécution de `gitlab-ctl reconfigure`, nous définissons et installons plusieurs ajustements sysctl pour améliorer les performances de PostgreSQL et augmenter les limites de connexion. Cela ne peut être effectué qu'avec un accès root.

## `gitlab-rake assets:precompile` échoue avec `Permission denied` {#gitlab-rake-assetsprecompile-fails-with-permission-denied}

Certains utilisateurs signalent que l'exécution de `gitlab-rake assets:precompile` ne fonctionne pas avec les packages Linux. La réponse courte est la suivante : n'exécutez pas cette commande, elle est uniquement destinée aux installations GitLab depuis les sources.

L'interface web de GitLab utilise des fichiers CSS et JavaScript, appelés « assets » dans le jargon Ruby on Rails. Dans le [dépôt GitLab upstream](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets), ces fichiers sont stockés de manière adaptée aux développeurs : faciles à lire et à modifier. Cependant, lorsque vous êtes un utilisateur ordinaire de GitLab, vous ne souhaitez pas que ces fichiers soient dans un format adapté aux développeurs, car cela ralentit GitLab. C'est pourquoi une partie du processus de configuration de GitLab consiste à convertir les assets d'un format adapté aux développeurs vers un format adapté aux utilisateurs finaux (compact et rapide) ; c'est à cela que sert le script `rake assets:precompile`.

Lorsque vous installez GitLab depuis les sources (qui était la seule façon de le faire avant que nous ayons des packages Linux), vous devez convertir les assets sur votre serveur GitLab chaque fois que vous mettez à jour GitLab. Les gens avaient tendance à oublier cette étape et il existe encore des publications, commentaires et e-mails sur Internet où les utilisateurs se recommandent mutuellement d'exécuter `rake assets:precompile` (qui a maintenant été renommé `gitlab:assets:compile`). Avec les packages Linux, les choses sont différentes. Lorsque nous construisons le package, [nous compilons les assets pour vous](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74). Lorsque vous installez GitLab avec un package Linux, les assets convertis sont déjà présents ! C'est pourquoi vous n'avez pas besoin d'exécuter `rake assets:precompile` lorsque vous installez GitLab depuis un package.

Lorsque `gitlab-rake assets:precompile` échoue avec une erreur de permission, cela échoue pour une bonne raison du point de vue de la sécurité : le fait que les assets ne puissent pas être facilement réécrits rend plus difficile pour un attaquant d'utiliser votre serveur GitLab pour servir du code JavaScript malveillant aux visiteurs de votre serveur GitLab.

Si vous souhaitez exécuter GitLab avec du code JavaScript ou CSS personnalisé, vous feriez probablement mieux d'exécuter GitLab depuis les sources ou de construire vos propres packages.

Si vous savez vraiment ce que vous faites, vous pouvez exécuter `gitlab-rake gitlab:assets:compile` comme ceci :

```shell
sudo NO_PRIVILEGE_DROP=true USE_DB=false gitlab-rake gitlab:assets:clean gitlab:assets:compile
# user and path might be different if you changed the defaults of
# user['username'], user['group'] and gitlab_rails['dir'] in gitlab.rb
sudo chown -R git:git /var/opt/gitlab/gitlab-rails/tmp/cache
```

## Erreur : `Short read or OOM loading DB` {#error-short-read-or-oom-loading-db}

Essayez de [nettoyer l'ancienne session Redis](https://docs.gitlab.com/administration/operations/).

## Erreur : `The requested URL returned error: 403` {#error-the-requested-url-returned-error-403}

Lors d'une tentative d'installation de GitLab à l'aide du dépôt apt, si vous recevez une erreur similaire à :

```shell
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

vérifiez s'il y a un cache de dépôt devant votre serveur, par exemple `apt-cacher-ng`.

Ajoutez la ligne suivante à la configuration d'apt-cacher-ng (par exemple dans `/etc/apt-cacher-ng/acng.conf`) :

```shell
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com|*\.cloudfront\.net)
```

Pour plus de détails sur la raison pour laquelle cette règle de passage est requise et comment la configurer, consultez la documentation de `apt-cacher-ng` pour les dépôts HTTPS/TLS.

## La mise en miroir de packages pour plusieurs distributions avec apt-mirror échoue {#mirroring-packages-for-multiple-distributions-using-apt-mirror-fails}

Les packages deb de GitLab CE et GitLab EE partagent les mêmes chaînes de version entre les distributions, mais ont un contenu différent. Dans le format de dépôt Debian, ils sont traités comme des [packages dupliqués](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages). Cela signifie qu'un seul dépôt deb ne peut pas servir plusieurs distributions en toute sécurité, car les métadonnées de package d'une distribution peuvent écraser celles d'une autre.

Nous publions chaque distribution sous un chemin dédié. Cependant, des redirections d'URL sont en place pour rediriger les requêtes vers l'URL `https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>` vers la distribution correcte `https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>/<distribution>` en fonction de la distribution utilisée par l'hôte, afin que les utilisateurs puissent continuer à utiliser la même URL pour différentes distributions.

Cependant, cette technique ne fonctionnera pas lorsque des outils de mise en miroir tels que `apt-mirror` sont utilisés pour mettre en miroir plusieurs distributions depuis le même hôte, car ils peuvent récupérer les métadonnées ou les packages pour la mauvaise distribution.

Rendez la distribution explicite en l'ajoutant au chemin d'URL. Par exemple, pour Jammy :

```plaintext
deb https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-ee/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-fips/ubuntu/jammy jammy main
```

Avec ce format, les emplacements clés sont :

- `InRelease` se trouve à `https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/InRelease`.
- `Packages.gz` se trouve à `https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/main/binary-amd64/Packages.gz`.
- Les fichiers de package se trouvent à `https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/pool/main/g/gitlab-ce/gitlab-ce_18.5.0-ce.0_amd64.deb`.

### `gitlab-runner` {#gitlab-runner}

La configuration des packages `gitlab-runner` est différente car le même package est utilisé dans toutes les distributions. L'URL peut rester : `https://packages.gitlab.com/runner/gitlab-runner`.

## Utilisation d'un certificat auto-signé ou d'autorités de certification personnalisées {#using-self-signed-certificate-or-custom-certificate-authorities}

Si vous installez GitLab dans un réseau isolé avec des autorités de certification personnalisées ou en utilisant un certificat auto-signé, assurez-vous que le certificat est accessible par GitLab. Ne pas le faire entraînera des erreurs telles que :

```shell
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

lorsque GitLab tente de se connecter aux services internes tels que GitLab Shell.

Pour corriger ces erreurs, consultez la section [Installer des certificats publics personnalisés](settings/ssl/_index.md#install-custom-public-certificates).

## Erreur : `proxyRoundTripper: XXX failed with: "net/http: timeout awaiting response headers"` {#error-proxyroundtripper-xxx-failed-with-nethttp-timeout-awaiting-response-headers}

Si GitLab Workhorse ne reçoit pas de réponse de GitLab dans un délai d'1 minute (par défaut), il servira une page 502.

Il existe diverses raisons pour lesquelles la requête peut expirer, peut-être que l'utilisateur chargeait une très grande diff ou quelque chose de similaire.

Vous pouvez augmenter la valeur du délai d'expiration par défaut en définissant la valeur dans `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_workhorse['proxy_headers_timeout'] = "2m0s"
```

Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## La modification souhaitée a été rejetée {#the-change-you-wanted-was-rejected}

Vous avez très probablement GitLab configuré dans un environnement qui dispose d'un proxy devant GitLab et les en-têtes de proxy définis par défaut dans le package sont incorrects pour votre environnement.

Consultez [la section Modifier les en-têtes de proxy par défaut de la documentation NGINX](settings/nginx.md#change-the-default-proxy-headers) pour plus de détails sur la façon de remplacer les en-têtes par défaut.

## Impossible de vérifier l'authenticité du jeton CSRF - Traitement 422 non traitable {#cant-verify-csrf-token-authenticity-completed-422-unprocessable}

Vous avez très probablement GitLab configuré dans un environnement qui dispose d'un proxy devant GitLab et les en-têtes de proxy définis par défaut dans le package sont incorrects pour votre environnement.

Consultez [la section Modifier les en-têtes de proxy par défaut de la documentation NGINX](settings/nginx.md#change-the-default-proxy-headers) pour plus de détails sur la façon de remplacer les en-têtes par défaut.

## Extension manquante `pg_trgm` {#extension-missing-pg_trgm}

[GitLab requiert](https://docs.gitlab.com/install/postgresql_extensions/) l'extension PostgreSQL `pg_trgm`. Si vous utilisez un package Linux avec la base de données intégrée, l'extension devrait être automatiquement activée lors de la mise à niveau.

Cependant, si vous utilisez une base de données externe (non packagée), vous devrez activer l'extension manuellement. La raison en est que les instances de packages Linux avec une base de données externe n'ont aucun moyen de confirmer si l'extension existe, et ne disposent pas non plus d'un moyen de l'activer.

Pour résoudre ce problème, vous devrez d'abord installer l'extension `pg_trgm`. L'extension se trouve dans le package `postgresql-contrib`. Pour Debian :

```shell
sudo apt-get install postgresql-contrib
```

Une fois l'extension installée, accédez à `psql` en tant que superutilisateur et activez l'extension.

1. Accédez à `psql` en tant que superutilisateur :

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. Activez l'extension :

   ```plaintext
   CREATE EXTENSION pg_trgm;
   \q
   ```

1. Exécutez maintenant à nouveau les migrations :

   ```shell
   sudo gitlab-rake db:migrate
   ```

---

Si vous utilisez Docker, vous devez d'abord accéder à votre conteneur, puis exécuter les commandes ci-dessus, et enfin redémarrer le conteneur.

1. Accédez au conteneur :

   ```shell
   docker exec -it gitlab bash
   ```

1. Exécutez les commandes ci-dessus.
1. Redémarrez le conteneur :

   ```shell
   docker restart gitlab
   ```

## Erreur : `Errno::ENOMEM: Cannot allocate memory during backup or upgrade` {#error-errnoenomem-cannot-allocate-memory-during-backup-or-upgrade}

[GitLab requiert](https://docs.gitlab.com/install/requirements/#memory) 2 Go de mémoire disponible pour fonctionner sans erreurs. Disposer de 2 Go de mémoire installée peut ne pas être suffisant selon l'utilisation des ressources par les autres processus sur votre serveur. Si GitLab fonctionne correctement lorsqu'il n'effectue pas de mise à niveau ou de sauvegarde, l'ajout de davantage de swap devrait résoudre votre problème. Si vous voyez le serveur utiliser le swap lors d'une utilisation normale, vous pouvez ajouter plus de RAM pour améliorer les performances.

## Erreur NGINX : `could not build server_names_hash, you should increase server_names_hash_bucket_size` {#nginx-error-could-not-build-server_names_hash-you-should-increase-server_names_hash_bucket_size}

Si l'URL externe de votre GitLab est plus longue que la taille de compartiment par défaut (64 octets), NGINX peut cesser de fonctionner et afficher cette erreur dans les journaux. Pour autoriser des noms de serveur plus longs, doublez la taille du compartiment dans `/etc/gitlab/gitlab.rb` :

```ruby
nginx['server_names_hash_bucket_size'] = 128
```

Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.

## Reconfigure échoue en raison de `'root' cannot chown` avec NFS root_squash {#reconfigure-fails-due-to-root-cannot-chown-with-nfs-root_squash}

```shell
$ gitlab-ctl reconfigure

================================================================================
Error executing action `run` on resource 'ruby_block[directory resource: /gitlab-data/git-data]'
================================================================================

Errno::EPERM
------------
'root' cannot chown /gitlab-data/git-data. If using NFS mounts you will need to re-export them in 'no_root_squash' mode and try again.
Operation not permitted @ chown_internal - /gitlab-data/git-data
```

Cela peut se produire si vous avez des répertoires montés avec NFS et configurés en mode `root_squash`. Reconfigure n'est pas en mesure de définir correctement la propriété de vos répertoires. Vous devrez passer à l'utilisation de `no_root_squash` dans vos exports NFS sur le serveur NFS, ou [désactiver la gestion des répertoires de stockage](settings/configuration.md#disable-storage-directories-management) et gérer vous-même les permissions.

## `gitlab-runsvdir` ne démarre pas {#gitlab-runsvdir-not-starting}

Ceci s'applique aux systèmes d'exploitation utilisant systemd (par exemple Ubuntu 18.04+, CentOS, etc.).

`gitlab-runsvdir` démarre pendant la cible `multi-user.target` au lieu de `basic.target`. Si vous avez des problèmes pour démarrer ce service après la mise à niveau de GitLab, vous devrez peut-être vérifier que votre système a correctement démarré tous les services requis pour `multi-user.target` via la commande :

```shell
systemctl -t target
```

Si tout fonctionne correctement, la sortie devrait ressembler à ceci :

```plaintext
UNIT                   LOAD   ACTIVE SUB    DESCRIPTION
basic.target           loaded active active Basic System
cloud-config.target    loaded active active Cloud-config availability
cloud-init.target      loaded active active Cloud-init target
cryptsetup.target      loaded active active Encrypted Volumes
getty.target           loaded active active Login Prompts
graphical.target       loaded active active Graphical Interface
local-fs-pre.target    loaded active active Local File Systems (Pre)
local-fs.target        loaded active active Local File Systems
multi-user.target      loaded active active Multi-User System
network-online.target  loaded active active Network is Online
network-pre.target     loaded active active Network (Pre)
network.target         loaded active active Network
nss-user-lookup.target loaded active active User and Group Name Lookups
paths.target           loaded active active Paths
remote-fs-pre.target   loaded active active Remote File Systems (Pre)
remote-fs.target       loaded active active Remote File Systems
slices.target          loaded active active Slices
sockets.target         loaded active active Sockets
swap.target            loaded active active Swap
sysinit.target         loaded active active System Initialization
time-sync.target       loaded active active System Time Synchronized
timers.target          loaded active active Timers

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.

22 loaded units listed. Pass --all to see loaded but inactive units, too.
To show all installed unit files use 'systemctl list-unit-files'.
```

Chaque ligne devrait afficher `loaded active active`. Comme illustré dans la ligne ci-dessous, si vous voyez `inactive dead`, cela signifie qu'il peut y avoir un problème :

```plaintext
multi-user.target      loaded inactive dead   start Multi-User System
```

Pour examiner quels jobs peuvent être mis en file d'attente par systemd, exécutez :

```shell
systemctl list-jobs
```

Si vous voyez un job `running`, un service peut être bloqué et empêcher ainsi GitLab de démarrer. Par exemple, certains utilisateurs ont eu des problèmes avec Plymouth qui ne démarrait pas :

```plaintext
  1 graphical.target                     start waiting
107 plymouth-quit-wait.service           start running
  2 multi-user.target                    start waiting
169 ureadahead-stop.timer                start waiting
121 gitlab-runsvdir.service              start waiting
151 system-getty.slice                   start waiting
 31 setvtrgb.service                     start waiting
122 systemd-update-utmp-runlevel.service start waiting
```

Dans ce cas, envisagez de désinstaller Plymouth.

## Détection du démon init dans un conteneur non-Docker {#init-daemon-detection-in-non-docker-container}

Dans les conteneurs Docker, le package GitLab détecte l'existence du fichier `/.dockerenv` et ignore la détection automatique d'un système init. Cependant, dans les conteneurs non-Docker (comme containerd, cri-o, etc.), ce fichier n'existe pas et le package revient à sysvinit, ce qui peut causer des problèmes lors de l'installation. Pour éviter cela, les utilisateurs peuvent explicitement désactiver la détection du démon init en ajoutant le paramètre suivant dans le fichier `gitlab.rb` :

```ruby
package['detect_init'] = false
```

Si vous utilisez cette configuration, le service runit doit être démarré avant d'exécuter `gitlab-ctl reconfigure`, à l'aide de la commande `runsvdir-start` :

```shell
/opt/gitlab/embedded/bin/runsvdir-start &
```

## `gitlab-ctl reconfigure` se bloque lors de l'utilisation d'AWS Cloudformation {#gitlab-ctl-reconfigure-hangs-while-using-aws-cloudformation}

Le fichier d'unité systemd de GitLab utilise par défaut `multi-user.target` pour les champs `After` et `WantedBy`. Cela est fait pour s'assurer que le service s'exécute après les cibles `remote-fs` et `network`, et que GitLab fonctionne correctement.

Cependant, cela interagit mal avec l'ordonnancement des unités de [cloud-init](https://cloudinit.readthedocs.io/en/latest/), utilisé par AWS Cloudformation.

Pour résoudre ce problème, les utilisateurs peuvent utiliser les paramètres `package['systemd_wanted_by']` et `package['systemd_after']` dans `gitlab.rb` pour spécifier les valeurs nécessaires à un ordonnancement correct et exécuter `sudo gitlab-ctl reconfigure`. Une fois la reconfiguration terminée, redémarrez le service `gitlab-runsvdir` pour que les modifications prennent effet.

```shell
sudo systemctl restart gitlab-runsvdir
```

## Erreur : `Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)` {#error-errnoeafnosupport-address-family-not-supported-by-protocol---socket2}

Lors du démarrage de GitLab, si une erreur similaire à la suivante est observée :

```ruby
FATAL: Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)
```

Vérifiez si les noms d'hôte utilisés sont résolvables et si des adresses **IPv4** sont retournées :

```shell
getent hosts gitlab.example.com
# Example IPv4 output: 192.168.1.1 gitlab.example.com
# Example IPv6 output: 2002:c0a8:0101::c0a8:0101 gitlab.example.com

getent hosts localhost
# Example IPv4 output: 127.0.0.1 localhost
# Example IPv6 output: ::1 localhost
```

Si un format d'adresse **IPv6** est retourné, vérifiez également si la prise en charge du protocole **IPv6** (mot-clé `ipv6`) est activée sur l'interface réseau :

```shell
ip addr # or 'ifconfig' on older operating systems
```

Lorsque la prise en charge du protocole réseau **IPv6** est absente ou désactivée, mais que la configuration DNS résout les noms d'hôte en adresses **IPv6**, les services GitLab ne pourront pas établir de connexions réseau.

Cela peut être résolu en corrigeant les configurations DNS (ou `/etc/hosts`) pour résoudre les hôtes en une adresse **IPv4** plutôt qu'en **IPv6**.

## Erreur : `... bad component(expected host component: my_url.tld)` lorsque `external_url` contient des underscores {#error--bad-componentexpected-host-component-my_urltld-when-external_url-contains-underscores}

Si vous avez défini `external_url` avec des underscores (par exemple `https://my_company.example.com`), vous pourriez rencontrer les problèmes suivants avec CI/CD :

- Il ne sera pas possible d'ouvrir la page **Paramètres > CI/CD** du projet.
- Les runners ne récupèreront pas les jobs et échoueront avec une erreur 500.

Si c'est le cas, [`production.log`](https://docs.gitlab.com/administration/logs/#productionlog) contiendra l'erreur suivante :

```plaintext
Completed 500 Internal Server Error in 50ms (ActiveRecord: 4.9ms | Elasticsearch: 0.0ms | Allocations: 17672)

URI::InvalidComponentError (bad component(expected host component): my_url.tld):

lib/api/helpers/related_resources_helpers.rb:29:in `expose_url'
ee/app/controllers/ee/projects/settings/ci_cd_controller.rb:19:in `show'
ee/lib/gitlab/ip_address_state.rb:10:in `with'
ee/app/controllers/ee/application_controller.rb:44:in `set_current_ip_address'
app/controllers/application_controller.rb:486:in `set_current_admin'
lib/gitlab/session.rb:11:in `with_session'
app/controllers/application_controller.rb:477:in `set_session_storage'
lib/gitlab/i18n.rb:73:in `with_locale'
lib/gitlab/i18n.rb:79:in `with_user_locale'
```

Pour contourner le problème, évitez d'utiliser des underscores dans `external_url`. Il existe un ticket ouvert à ce sujet :  [La définition de `external_url` avec un underscore entraîne un dysfonctionnement de la fonctionnalité GitLab CI/CD](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6077).

## La mise à niveau échoue avec une erreur `timeout: run: /opt/gitlab/service/gitaly` {#upgrade-fails-with-timeout-run-optgitlabservicegitaly-error}

Si la mise à niveau du package échoue lors de l'exécution de reconfigure avec l'erreur suivante, vérifiez que tous les processus Gitaly sont arrêtés, puis réexécutez `sudo gitlab-ctl reconfigure`.

```plaintext
---- Begin output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
STDOUT: timeout: run: /opt/gitlab/service/gitaly: (pid 4886) 15030s, got TERM
STDERR:
---- End output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
Ran /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly returned 1
```

Consultez le [ticket 341573](https://gitlab.com/gitlab-org/gitlab/-/issues/341573) pour plus de détails.

## Reconfigure est bloqué lors de la réinstallation de GitLab {#reconfigure-is-stuck-when-re-installing-gitlab}

En raison d'un [problème connu](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776), vous pouvez voir le processus de reconfiguration bloqué à `ruby_block[wait for logrotate service socket] action run` après avoir désinstallé GitLab et tenté de le réinstaller. Ce problème se produit lorsqu'une des commandes `systemctl` n'est pas exécutée lors de la [désinstallation de GitLab](https://docs.gitlab.com/install/package/#uninstall-the-linux-package).

Pour résoudre ce problème :

- Assurez-vous d'avoir suivi toutes les étapes lors de la désinstallation de GitLab et effectuez-les si nécessaire.
- Suivez la solution de contournement dans le [ticket 7776](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776).

## La mise en miroir du dépôt `yum` de GitLab avec Pulp ou Red Hat Satellite échoue {#mirroring-the-gitlab-yum-repository-with-pulp-or-red-hat-satellite-fails}

La mise en miroir directe des dépôts `yum` du package Linux situés à <https://packages.gitlab.com/gitlab/> avec [Pulp](https://pulpproject.org/) ou [Red Hat Satellite](https://www.redhat.com/en/technologies/management/satellite) échoue lors de la synchronisation. Différentes erreurs sont causées par différents logiciels :

- Pulp 2 ou Satellite < 6.10 échoue avec l'erreur `"Malformed repository: metadata is specified for different set of packages in filelists.xml and in other.xml"`.
- Satellite 6.10 échoue avec l'erreur `"pkgid"`.
- Pulp 3 ou Satellite > 6.10 semble réussir, mais seules les métadonnées du dépôt sont synchronisées.

Ces échecs de synchronisation sont causés par des problèmes avec les métadonnées dans le dépôt miroir `yum` de GitLab. Ces métadonnées incluent un fichier `filelists.xml.gz` qui contient normalement une liste de fichiers pour chaque RPM dans le dépôt. Le dépôt `yum` de GitLab laisse ce fichier principalement vide pour contourner un problème de taille qui se produirait si le fichier était entièrement rempli.

Chaque RPM de GitLab contient un nombre considérable de fichiers, ce qui, multiplié par le grand nombre de RPM dans le dépôt, résulterait en un énorme fichier `filelists.xml.gz` s'il était entièrement rempli. En raison de contraintes de stockage et de compilation, nous créons le fichier mais ne le remplissons pas. Le fichier vide provoque l'échec de la mise en miroir du dépôt par Pulp et RedHat Satellite (qui utilise Pulp).

Consultez le [ticket 2766](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2766) pour plus de détails.

### Contournement du problème {#work-around-the-issue}

Pour contourner le problème :

1. Utilisez un outil de mise en miroir de dépôt RPM alternatif comme `reposync` ou `createrepo` pour effectuer une copie locale du dépôt `yum` officiel de GitLab. Ces outils recréent les métadonnées du dépôt dans les données locales, ce qui inclut la création d'un fichier `filelists.xml.gz` entièrement rempli.
1. Pointez Pulp ou Satellite vers le miroir local.

### Exemple de miroir local {#local-mirror-example}

Ce qui suit est un exemple de la façon de faire de la mise en miroir locale. L'exemple utilise :

- [Apache](https://httpd.apache.org/) comme serveur web pour le dépôt.
- [`reposync`](https://dnf-plugins-core.readthedocs.io/en/latest/reposync.html) et [`createrepo`](http://createrepo.baseurl.org/) pour synchroniser le dépôt GitLab vers le miroir local. Ce miroir local peut ensuite être utilisé comme source pour Pulp ou RedHat Satellite. Vous pouvez également utiliser d'autres outils comme [Cobbler](https://cobbler.github.io/).

Dans cet exemple :

- Le miroir local s'exécute sur un système `RHEL 8`, `Rocky 8` ou `AlmaLinux 8`.
- Le nom d'hôte utilisé pour le serveur web est `mirror.example.com`.
- Pulp 3 se synchronise depuis le miroir local.
- La mise en miroir concerne le [dépôt GitLab Enterprise Edition](https://packages.gitlab.com/gitlab/gitlab-ee).

#### Créer et configurer un serveur Apache {#create-and-configure-an-apache-server}

L'exemple suivant montre comment installer et configurer un serveur Apache 2 de base pour héberger un ou plusieurs miroirs de dépôt Yum. Consultez la documentation [Apache](https://httpd.apache.org/) pour plus de détails sur la configuration et la sécurisation de votre serveur web.

1. Installez `httpd` :

   ```shell
   sudo dnf install httpd
   ```

1. Ajoutez une section `Directory` à `/etc/httpd/conf/httpd.conf` :

   ```apache
   <Directory "/var/www/html/repos">
   Options All Indexes FollowSymLinks
   Require all granted
   </Directory>
   ```

1. Complétez la configuration de `httpd` :

   ```shell
   sudo rm -f /etc/httpd/conf.d/welcome.conf
   sudo mkdir /var/www/html/repos
   sudo systemctl enable httpd --now
   ```

#### Obtenir l'URL du dépôt Yum mis en miroir {#get-the-mirrored-yum-repository-url}

1. Installez le fichier de configuration `yum` du dépôt GitLab :

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   sudo dnf config-manager --disable gitlab_gitlab-ee gitlab_gitlab-ee-source
   ```

1. Obtenez l'URL du dépôt :

   ```shell
   sudo dnf config-manager --dump gitlab_gitlab-ee | grep baseurl
   baseurl = https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64
   ```

   Utilisez le contenu de `baseurl` comme source du miroir local. Par exemple, `https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64`.

#### Créer le miroir local {#create-the-local-mirror}

1. Installez le package `createrepo` :

   ```shell
   sudo dnf install createrepo
   ```

1. Exécutez `reposync` pour copier les RPM vers le miroir local :

   ```shell
   sudo dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only
   ```

   L'option `--newest-only` télécharge uniquement le RPM le plus récent. Si vous omettez cette option, tous les RPM du dépôt (environ 1 Go chacun) sont téléchargés.

1. Exécutez `createrepo` pour recréer les métadonnées du dépôt :

   ```shell
   sudo createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
   ```

Le dépôt miroir local devrait maintenant être disponible à <http://mirror.example.com/repos/gitlab_gitlab-ee/>.

#### Mettre à jour le miroir local {#update-the-local-mirror}

Votre miroir local doit être mis à jour périodiquement pour obtenir de nouveaux RPM au fur et à mesure que de nouvelles versions de GitLab sont publiées. Une façon de procéder est d'utiliser `cron`.

Créez `/etc/cron.daily/sync-gitlab-mirror` avec le contenu suivant :

```shell
#!/bin/sh

dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only --delete
createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
```

L'option `--delete` utilisée dans la commande `dnf reposync` supprime les RPM dans le miroir local qui ne sont plus présents dans le dépôt GitLab correspondant.

#### Utilisation du miroir local {#using-the-local-mirror}

1. Créez le `repository` et le `remote` Pulp :

   ```shell
   pulp rpm repository create --retain-package-versions=1 --name "gitlab-ee"
   pulp rpm remote create --name gitlab-ee --url "http://mirror.example.com/repos/gitlab_gitlab-ee/" --policy immediate
   pulp rpm repository update --name gitlab-ee --remote gitlab-ee
   ```

1. Synchronisez le dépôt :

   ```shell
   pulp rpm repository sync --name gitlab-ee
   ```

   Cette commande doit être exécutée périodiquement pour mettre à jour le miroir local avec les modifications apportées au dépôt GitLab.

Une fois le dépôt synchronisé, vous pouvez créer une publication et une distribution pour le rendre disponible. Consultez <https://docs.pulpproject.org/pulp_rpm/> pour plus de détails.

## Erreur : `E: connection refused to d20rj4el6vkp4c.cloudfront.net 443` {#error-e-connection-refused-to-d20rj4el6vkp4ccloudfrontnet-443}

Lorsque vous installez un package hébergé sur notre dépôt de packages à `packages.gitlab.com`, votre client recevra et suivra une redirection vers l'adresse CloudFront `d20rj4el6vkp4c.cloudfront.net`. Les serveurs dans un environnement isolé (air-gapped) peuvent recevoir les erreurs suivantes :

```shell
E: connection refused to d20rj4el6vkp4c.cloudfront.net 443
```

```shell
Failed to connect to d20rj4el6vkp4c.cloudfront.net port 443: Connection refused
```

Pour résoudre ce problème, vous avez trois options :

- Si vous pouvez autoriser par domaine, ajoutez le point de terminaison `d20rj4el6vkp4c.cloudfront.net` à vos paramètres de pare-feu.
- Si vous ne pouvez pas autoriser par domaine, ajoutez les [plages d'adresses IP CloudFront](https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips) à vos paramètres de pare-feu. Vous devez maintenir cette liste synchronisée avec vos paramètres de pare-feu car ils peuvent changer.
- Téléchargez manuellement le fichier du package et téléversez-le sur votre serveur.

## Erreur : `503 Service Unavailable` pour les opérations de stockage de packages {#error-503-service-unavailable-for-package-storage-operations}

Certains composants de stockage de packages sont servis via Google Cloud Storage (GCS). Ces composants nécessitent un accès HTTPS sortant au point de terminaison GCS en plus du point de terminaison public du dépôt APT. Si `apt update` échoue avec une erreur `503 Service Unavailable`, l'accès à `storage.googleapis.com/packages-ops` est bloqué.

Pour résoudre cette erreur, assurez-vous que vos règles de pare-feu autorisent les connexions HTTPS sortantes (port `443`) vers :

- `packages.gitlab.com`
- `storage.googleapis.com`
- Compartiment `packages-ops` sur Google Cloud Storage

## Vérifier si `net.core.somaxconn` est trop faible {#check-if-netcoresomaxconn-is-set-too-low}

Ce qui suit peut aider à identifier si la valeur de `net.core.somaxconn` est trop faible :

```shell
$ netstat -ant | grep -c SYN_RECV
4
```

La valeur retournée par `netstat -ant | grep -c SYN_RECV` est le nombre de connexions en attente d'être établies. Si la valeur est supérieure à `net.core.somaxconn` :

```shell
$ sysctl net.core.somaxconn
net.core.somaxconn = 1024
```

Vous pouvez rencontrer des délais d'expiration ou des erreurs HTTP 502 et il est recommandé d'augmenter cette valeur en mettant à jour la variable `puma['somaxconn']` dans votre `gitlab.rb`.

## Erreur : `exec request failed on channel 0` ou `shell request failed on channel 0` {#error-exec-request-failed-on-channel-0-or-shell-request-failed-on-channel-0}

Lors d'opérations de pull ou push avec Git via SSH, vous pourriez voir les erreurs suivantes :

- `exec request failed on channel 0`
- `shell request failed on channel 0`

Ces erreurs peuvent se produire si le nombre de processus de l'utilisateur `git` dépasse la limite.

Pour tenter de résoudre ce problème :

1. Augmentez le paramètre `nproc` pour l'utilisateur `git` dans le fichier `/etc/security/limits.conf` sur les nœuds où `gitlab-shell` s'exécute. En général, `gitlab-shell` s'exécute sur les nœuds GitLab Rails.
1. Réessayez la commande Git de pull ou de push.

## Installation bloquée après perte de connexion SSH {#hung-installation-after-ssh-connection-loss}

Si vous installez GitLab sur une machine virtuelle distante et que votre connexion SSH est perdue, l'installation peut se bloquer avec un processus `dpkg` zombie. Pour reprendre l'installation :

1. Exécutez `top` pour trouver l'ID de processus du processus `apt` associé, qui est le parent du processus `dpkg`.
1. Arrêtez le processus `apt` en exécutant `sudo kill <PROCESS_ID>`.
1. Uniquement en cas d'installation fraîche, exécutez `sudo gitlab-ctl cleanse`. Cette étape efface les données existantes et ne doit donc pas être utilisée lors de mises à niveau.
1. Exécutez `sudo dpkg configure -a`.
1. Modifiez le fichier `gitlab.rb` pour inclure l'URL externe souhaitée et toute autre configuration éventuellement manquante.
1. Exécutez `sudo gitlab-ctl reconfigure`.

## Erreur liée à Redis lors de la reconfiguration de GitLab {#redis-related-error-when-reconfiguring-gitlab}

Vous pouvez rencontrer l'erreur suivante lors de la reconfiguration de GitLab :

```plaintext
RuntimeError: redis_service[redis] (redis::enable line 19) had an error: RuntimeError: ruby_block[warn pending redis restart] (redis::enable line 77) had an error: RuntimeError: Execution of the command /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket INFO failed with a non-zero exit code (1)
```

Le message d'erreur indique que Redis a peut-être redémarré ou s'est arrêté lors d'une tentative d'établissement d'une connexion avec `redis-cli`. Étant donné que la recette exécute `gitlab-ctl restart redis` et tente de vérifier la version immédiatement après, il peut y avoir une condition de compétition qui cause l'erreur.

Pour résoudre ce problème, exécutez la commande suivante :

```shell
sudo gitlab-ctl reconfigure
```

Si cela échoue, vérifiez la sortie de `gitlab-ctl tail redis` et essayez d'exécuter `redis-cli`.
