# Prometheus Settings

## Remote read/write

Prometheus supports reading and writing to remote services.

To configure a remote remote read or write service, you can include the following in `gitlab.rb`.

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

For more documentation on the options available, see the [remote write] and [remote read] sections of the official documentation.

[remote read]: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cremote_read%3E
[remote write]: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cremote_write%3E

## Rules files

Prometheus allows for [recording] and [alerting] rules.

Omnibus includes some [default rules files](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/templates/default/prometheus/rules)
that are stored in `/var/opt/gitlab/prometheus/rules/`.

To override the default rules, you can change the default list in `gitlab.rb.`.

No rules:

    prometheus['rules_files'] = []

Custom list:

    prometheus['rules_files'] = ['/path/to/rules/*.rules', '/path/to/single/file.rules']

## Grafana dashboards

[Grafana](https://grafana.com) is a powerful dashboard software for presenting
Prometheus metrics data. GitLab Omnibus >= 11.9 includes an embedded copy.

See [the embedded Grafana documentation](grafana.md) for more information.

[alerting]: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
[recording]: https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/

