---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres Prometheus
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Lecture/écriture à distance {#remote-readwrite}

Prometheus prend en charge la lecture et l'écriture vers des services distants.

Pour configurer un service de lecture ou d'écriture à distance, vous pouvez inclure les éléments suivants dans `gitlab.rb`.

```ruby
prometheus['remote_write'] = [
  {
    url: 'https://some-remote-write-service.example.com',
    basic_auth: {
      password: 'remote write secret password'
    }
  }
]
prometheus['remote_read'] = [
  {
    url: 'https://some-remote-write-service.example.com'
  }
]
```

Pour plus d'informations sur les options de configuration, consultez les informations relatives à la configuration de Prometheus :

- [`remote_write`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write).
- [`remote_read`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_read).

## Fichiers de règles {#rules-files}

Prometheus autorise les règles d'[enregistrement](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) et d'[alertes](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/).

Les installations de packages Linux incluent quelques [fichiers de règles par défaut](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/monitoring/templates/rules) stockés dans `/var/opt/gitlab/prometheus/rules/`.

Pour remplacer les règles par défaut, vous pouvez modifier la liste par défaut dans `gitlab.rb.`.

Aucune règle :

```ruby
prometheus['rules_files'] = []
```

Liste personnalisée :

```ruby
prometheus['rules_files'] = ['/path/to/rules/*.rules', '/path/to/single/file.rules']
```

## Labels externes {#external-labels}

Pour définir des [labels externes](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) :

```ruby
prometheus['external_labels'] = {
    'region' => 'us-west-2',
    'source' => 'omnibus',
}
```

Aucun label externe n'est défini par défaut.

## `node_exporter` {#node_exporter}

Le `node_exporter` fournit des métriques au niveau système.

Des collecteurs de métriques supplémentaires sont activés par défaut. Par exemple, `mountstats` est utilisé pour collecter des métriques sur les montages NFS.

Pour désactiver le collecteur `mountstats`, ajustez `gitlab.rb` avec le paramètre suivant et exécutez `gitlab-ctl reconfigure` :

```ruby
node_exporter['flags'] = {
  'collector.mountstats' => false,
}
```

Pour plus d'informations sur les collecteurs disponibles, consultez la [documentation officielle](https://github.com/prometheus/node_exporter#collectors).

## Options de l'Alertmanager {#alertmanager-options}

Vous pouvez définir des [options globales](https://prometheus.io/docs/alerting/latest/configuration/) pour l'[Alertmanager](https://prometheus.io/docs/alerting/latest/configuration/).

Par exemple, la configuration `gitlab.rb` suivante remplace le nom d'hôte qu'Alertmanager utilise pour s'identifier auprès du serveur SMTP :

```ruby
alertmanager['global'] = {
  'smtp_hello' => 'example.org'
}
```

### Récepteurs et routes supplémentaires {#additional-receivers-and-routes}

Dans cet exemple, nous implémentons un nouveau récepteur pour VictorOps.

1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter un nouveau récepteur et définir une [route](https://prometheus.io/docs/alerting/latest/configuration/#route) :

   ```ruby
   alertmanager['receivers'] = [
     {
       'name' => 'victorOps-receiver',
       'victorops_configs' => [
         {
           'routing_key'         => 'Sample_route',
           'api_key'             => '558e7ebc-XXXX-XXXX-XXXX-XXXXXXXXXXXX',
           'entity_display_name' => '{{ .CommonAnnotations.summary }}',
           'message_type'        => '{{ .CommonLabels.severity }}',
           'state_message'       => 'Alert: {{ .CommonLabels.alertname }}. Summary:{{ .CommonAnnotations.summary }}. RawData: {{ .CommonLabels }}',
           'http_config'         => {
             proxy_url: 'http://internet.proxy.com:3128'
           }
         } #, { Next receiver }
       ]
     }
   ]

   alertmanager['routes'] = [
     {
       'receiver'        => 'victorOps-receiver',
       'group_wait'      => '30s',
       'group_interval'  => '5m',
       'repeat_interval' => '3h',
       'matchers'        => [ 'severity = high' ]
     } #, { Next route }
   ]
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Alertmanager acheminera désormais les alertes `severity = high` vers `victorops-receiver`.

Pour en savoir plus sur les options VictorOps pour Alertmanager, consultez la [documentation VictorOps](https://help.victorops.com/knowledge-base/victorops-prometheus-integration/).
