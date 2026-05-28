---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Journaux sur les installations de packages Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab inclut un [système de journalisation avancé](https://docs.gitlab.com/administration/logs/) où chaque service et composant de GitLab génère des journaux système. Voici les paramètres de configuration et les outils pour gérer ces journaux sur les installations de packages Linux.

## Suivre les journaux dans une console sur le serveur {#tail-logs-in-a-console-on-the-server}

Si vous souhaitez « suivre » (tail), c'est-à-dire consulter les mises à jour en direct des journaux GitLab, vous pouvez utiliser `gitlab-ctl tail`.

```shell
# Tail all logs; press Ctrl-C to exit
sudo gitlab-ctl tail

# Drill down to a sub-directory of /var/log/gitlab
sudo gitlab-ctl tail gitlab-rails

# Drill down to an individual file
sudo gitlab-ctl tail nginx/gitlab_error.log
```

### Suivre les journaux dans une console et les enregistrer dans un fichier {#tail-logs-in-a-console-and-save-to-a-file}

Il est souvent utile d'afficher simultanément les journaux dans la console et de les enregistrer dans un fichier pour un débogage/une analyse ultérieure. Vous pouvez utiliser l'utilitaire [`tee`](https://en.wikipedia.org/wiki/Tee_(command)) pour accomplir cela.

```shell
# Use 'tee' to tail all the logs to STDOUT and write to a file at the same time
sudo gitlab-ctl tail | tee --append /tmp/gitlab_tail.log
```

## Configurer les répertoires de journaux par défaut {#configure-default-log-directories}

Dans votre fichier `/etc/gitlab/gitlab.rb`, il existe de nombreuses clés `log_directory` pour les différents types de journaux. Décommentez et mettez à jour les valeurs pour tous les journaux que vous souhaitez placer ailleurs :

```ruby
# For example:
gitlab_rails['log_directory'] = "/var/log/gitlab/gitlab-rails"
puma['log_directory'] = "/var/log/gitlab/puma"
registry['log_directory'] = "/var/log/gitlab/registry"
...
```

Gitaly possède une configuration de répertoire de journaux différente :

```ruby
gitaly['configuration'] = {
   logging: {
    dir: "/var/log/gitlab/registry"
   }
}
```

Exécutez `sudo gitlab-ctl reconfigure` pour configurer votre instance avec ces paramètres.

## Journaux runit {#runit-logs}

Les services [gérés par runit](../development/architecture/_index.md#runit) dans les installations de packages Linux génèrent des données de journal à l'aide de `svlogd`.

- Les journaux sont écrits dans un fichier appelé `current`.
- Périodiquement, ce journal est compressé et renommé en utilisant le format TAI64N, par exemple : `@400000005f8eaf6f1a80ef5c.s`.
- L'horodatage du système de fichiers sur les journaux compressés sera cohérent avec la dernière fois que GitLab a écrit dans ce fichier.
- `zmore` et `zgrep` permettent d'afficher et de rechercher dans les journaux compressés ou non compressés.

Lisez la [documentation de `svlogd`](https://smarden.org/runit/svlogd.8) pour plus d'informations sur les fichiers qu'il génère.

Vous pouvez modifier les paramètres de `svlogd` dans `/etc/gitlab/gitlab.rb` avec les paramètres suivants :

```ruby
# Below are the default values
logging['svlogd_size'] = 200 * 1024 * 1024 # rotate after 200 MB of log data
logging['svlogd_num'] = 30 # keep 30 rotated log files
logging['svlogd_timeout'] = 24 * 60 * 60 # rotate after 24 hours
logging['svlogd_filter'] = "gzip" # compress logs with gzip
logging['svlogd_udp'] = nil # transmit log messages via UDP
logging['svlogd_prefix'] = nil # custom prefix for log messages

# Optionally, you can override the prefix for e.g. Nginx
nginx['svlogd_prefix'] = "nginx"
```

## Logrotate {#logrotate}

Le service **logrotate** intégré à GitLab gère tous les journaux à l'exception de ceux capturés par **runit**. Ce service effectue la rotation, la compression et la suppression éventuelle des données de journal telles que `gitlab-rails/production.log` et `nginx/gitlab_access.log`. Vous pouvez configurer les paramètres logrotate communs, configurer les paramètres logrotate par service, et désactiver complètement logrotate avec `/etc/gitlab/gitlab.rb`.

### Configurer les paramètres logrotate communs {#configuring-common-logrotate-settings}

Les paramètres communs à tous les services **logrotate** peuvent être définis dans le fichier `/etc/gitlab/gitlab.rb`. Ces paramètres correspondent aux options de configuration dans les fichiers de configuration logrotate pour chaque service. Consultez la page de manuel de logrotate (`man logrotate`) pour plus de détails.

```ruby
logging['logrotate_frequency'] = "daily" # rotate logs daily
logging['logrotate_maxsize'] = nil # logs will be rotated when they grow bigger than size specified for `maxsize`, even before the specified time interval (daily, weekly, monthly, or yearly)
logging['logrotate_size'] = nil # do not rotate by size by default
logging['logrotate_rotate'] = 30 # keep 30 rotated logs
logging['logrotate_compress'] = "compress" # see 'man logrotate'
logging['logrotate_method'] = "copytruncate" # see 'man logrotate'
logging['logrotate_postrotate'] = nil # no postrotate command by default
logging['logrotate_dateformat'] = nil # use date extensions for rotated files rather than numbers e.g. a value of "-%Y-%m-%d" would give rotated files like production.log-2016-03-09.gz
```

### Configurer les paramètres logrotate par service {#configuring-individual-service-logrotate-settings}

Vous pouvez personnaliser les paramètres logrotate pour chaque service individuel en utilisant `/etc/gitlab/gitlab.rb`. Par exemple, pour personnaliser la fréquence et la taille de logrotate pour le service `nginx`, utilisez :

```ruby
nginx['logrotate_frequency'] = nil
nginx['logrotate_size'] = "200M"
```

### Désactiver logrotate {#disabling-logrotate}

Vous pouvez également désactiver le service logrotate intégré avec le paramètre suivant dans `/etc/gitlab/gitlab.rb` :

```ruby
logrotate['enable'] = false
```

### Paramètre `notifempty` de Logrotate {#logrotate-notifempty-setting}

Le service logrotate s'exécute avec une valeur par défaut non configurable de `notifempty`, résolvant les problèmes suivants :

- Des journaux vides sont inutilement soumis à la rotation, et souvent de nombreux journaux vides sont stockés.
- Des journaux ponctuels utiles pour le dépannage à long terme sont supprimés après 30 jours, comme les journaux de migration de base de données.

### Gestion des journaux ponctuels et vides par Logrotate {#logrotate-one-off-and-empty-log-handling}

Les journaux sont désormais soumis à la rotation et recréés par **logrotate** selon les besoins, et les journaux ponctuels ne sont soumis à la rotation que lorsqu'ils changent. Avec ce paramètre en place, quelques opérations de nettoyage peuvent être effectuées :

- Les journaux ponctuels vides tels que `gitlab-rails/gitlab-rails-db-migrate*.log` peuvent être supprimés.
- Les journaux vides qui ont été soumis à la rotation et compressés par des versions antérieures de GitLab. Ces journaux vides ont généralement une taille de 20 octets.

### Exécuter logrotate manuellement {#run-logrotate-manually}

Logrotate est un job planifié, mais il peut également être déclenché à la demande.

Pour déclencher manuellement la rotation des journaux GitLab avec `logrotate`, utilisez la commande suivante :

```shell
/opt/gitlab/embedded/sbin/logrotate -fv -s /var/opt/gitlab/logrotate/logrotate.status /var/opt/gitlab/logrotate/logrotate.conf
```

### Augmenter la fréquence de déclenchement de logrotate {#increase-how-often-logrotate-is-triggered}

Le script logrotate se déclenche toutes les 50 minutes et attend 10 minutes avant de tenter d'effectuer la rotation des journaux.

Pour modifier ces valeurs :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   logrotate['pre_sleep'] = 600   # sleep 10 minutes before rotating after start-up
   logrotate['post_sleep'] = 3000 # wait 50 minutes after rotating
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Transfert de journaux UDP {#udp-log-forwarding}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les installations de packages Linux peuvent utiliser la fonctionnalité de journalisation UDP de svlogd ainsi qu'envoyer des journaux non-svlogd vers un système distant compatible syslog via UDP. Pour configurer une installation de package Linux afin d'envoyer des messages de protocole syslog via UDP, utilisez les paramètres suivants :

```ruby
logging['udp_log_shipping_host'] = '1.2.3.4' # Your syslog server
# logging['udp_log_shipping_hostname'] = nil # Optional, defaults the system hostname
logging['udp_log_shipping_port'] = 1514 # Optional, defaults to 514 (syslog)
```

> [!note]
> Le paramétrage de `udp_log_shipping_host` [ajoutera un `svlogd_prefix`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/logging.rb) pour le nom d'hôte et le service spécifiés pour chacun des services [gérés par runit](../development/architecture/_index.md#runit).

Exemples de messages de journal :

```plaintext
Jun 26 06:33:46 ubuntu1204-test production.log: Started GET "/root/my-project/import" for 127.0.0.1 at 2014-06-26 06:33:46 -0700
Jun 26 06:33:46 ubuntu1204-test production.log: Processing by ProjectsController#import as HTML
Jun 26 06:33:46 ubuntu1204-test production.log: Parameters: {"id"=>"root/my-project"}
Jun 26 06:33:46 ubuntu1204-test production.log: Completed 200 OK in 122ms (Views: 71.9ms | ActiveRecord: 12.2ms)
Jun 26 06:33:46 ubuntu1204-test gitlab_access.log: 172.16.228.1 - - [26/Jun/2014:06:33:46 -0700] "GET /root/my-project/import HTTP/1.1" 200 5775 "https://172.16.228.169/root/my-project/import" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36"
2014-06-26_13:33:46.49866 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7nbj0 Sidekiq::Extensions::DelayedMailer JID-bbfb118dd1db20f6c39f5b50 INFO: start
2014-06-26_13:33:46.52608 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7muoc RepositoryImportWorker JID-57ee926c3655fcfa062338ae INFO: start
```

## Utiliser un format de journal NGINX personnalisé {#using-a-custom-nginx-log-format}

Par défaut, les journaux d'accès NGINX utilisent une version du format NGINX « combined », conçu pour masquer les informations potentiellement sensibles intégrées dans les chaînes de requête. Si vous souhaitez utiliser une chaîne de format de journal personnalisée, vous pouvez la spécifier dans `/etc/gitlab/gitlab.rb` - consultez [la documentation NGINX](https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) pour les détails de format.

```ruby
nginx['log_format'] = 'my format string $foo $bar'
```

## Journalisation JSON {#json-logging}

Les journaux structurés peuvent être exportés via JSON pour être analysés par Elasticsearch, Splunk ou un autre système de gestion des journaux. Le format JSON est activé par défaut pour tous les services qui le prennent en charge.

> [!note]
> PostgreSQL ne prend pas en charge la journalisation JSON sans plugin externe. Cependant, il prend en charge la journalisation au format CSV :

```ruby
postgresql['log_destination'] = 'csvlog'
postgresql['logging_collector'] = 'on'
```

Un redémarrage de la base de données est nécessaire pour que cela prenne effet. Pour plus de détails, consultez la [documentation PostgreSQL](https://www.postgresql.org/docs/12/runtime-config-logging.html).

## Journalisation texte {#text-logging}

Les clients disposant de systèmes d'ingestion de journaux établis peuvent ne pas souhaiter utiliser le format de journal JSON. Le formatage texte peut être configuré en définissant les paramètres suivants dans `/etc/gitlab/gitlab.rb`, puis en exécutant `gitlab-ctl reconfigure` ensuite :

```ruby
gitaly['configuration'] = {
   logging: {
    format: ""
   }
}
gitlab_shell['log_format'] = 'text'
gitlab_workhorse['log_format'] = 'text'
registry['log_formatter'] = 'text'
sidekiq['log_format'] = 'text'
gitlab_pages['log_format'] = 'text'
```

> [!note]
> Il existe quelques variations dans les noms d'attributs pour le format de journal selon le service concerné (par exemple, le registre de conteneurs utilise `log_formatter`, Gitaly et Praefect utilisent tous deux `logging_format`). Consultez le [ticket n°4280](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4280) pour plus de détails.

## rbtrace {#rbtrace}

GitLab est livré avec [`rbtrace`](https://github.com/tmm1/rbtrace), qui vous permet de tracer du code Ruby, d'afficher tous les fils de discussion en cours d'exécution, de prendre des instantanés de mémoire, et bien plus encore. Cependant, cette fonctionnalité n'est pas activée par défaut. Pour l'activer, définissez la variable `ENABLE_RBTRACE` dans l'environnement :

```ruby
gitlab_rails['env'] = {"ENABLE_RBTRACE" => "1"}
```

Reconfigurez ensuite le système et redémarrez Puma et Sidekiq. Pour exécuter ceci dans une installation de package Linux, exécutez en tant que root :

```ruby
/opt/gitlab/embedded/bin/ruby /opt/gitlab/embedded/bin/rbtrace
```

## Configurer le niveau/la verbosité des journaux {#configuring-log-levelverbosity}

Vous pouvez configurer les niveaux de journalisation minimaux (verbosité) pour GitLab Rails, Container Registry, GitLab Shell et Gitaly :

1. Modifiez `/etc/gitlab/gitlab.rb` et définissez les niveaux de journalisation :

   ```ruby
   gitlab_rails['env'] = {
     "GITLAB_LOG_LEVEL" => "WARN",
   }
   registry['log_level'] = 'info'
   gitlab_shell['log_level'] = 'INFO'
   gitaly['configuration'] = {
     logging: {
       level: "warn"
     }
   }
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Vous [ne pouvez pas modifier](https://gitlab.com/groups/gitlab-org/-/epics/6034) le `log_level` pour certains journaux GitLab, par exemple `production_json.log`, `graphql_json.log`, etc. Voir aussi [Remplacer le niveau de journalisation par défaut](https://docs.gitlab.com/administration/logs/#override-default-log-level).

## Définir un groupe de journaux personnalisé {#setting-a-custom-log-group}

GitLab prend en charge l'attribution d'un groupe personnalisé aux [répertoires de journaux](#configure-default-log-directories) configurés

Un paramètre global `logging['log_group']` dans votre fichier `/etc/gitlab/gitlab.rb` peut être configuré ainsi que des paramètres `log_group` par service tels que `gitaly['log_group']`. Vous devrez exécuter `sudo gitlab-ctl reconfigure` pour configurer votre instance lors de l'ajout de paramètres `log_group`.

La définition d'un `log_group` global ou par service effectuera les opérations suivantes :

- Modifier les permissions sur les répertoires de journaux par service (ou tous les répertoires de journaux si vous utilisez le paramètre global) à `0750` pour permettre aux membres du groupe configuré de lire le contenu du répertoire de journaux.
- Configurer [runit](#runit-logs) pour écrire et effectuer la rotation des journaux en utilisant le `log_group` spécifié : soit par service, soit pour tous les services gérés par runit.

### Limitations du groupe de journaux personnalisé {#custom-log-group-limitations}

Les journaux des services non gérés par runit (par exemple, les journaux `gitlab-rails` dans `/var/log/gitlab/gitlab-rails`) n'hériteront pas du paramètre `log_group` configuré.

Le groupe doit déjà exister sur l'hôte. Les installations de packages Linux ne créent pas le groupe lors de l'exécution de `sudo gitlab-ctl reconfigure`.
