# Prometheus Settings

## Rules files

Prometheus allows for [recording] and [alerting] rules.

Omnibus includes some default rules files in `/var/opt/gitlab/prometheus/rules/`.

To override the default rules, you can change the default list in `gitlab.rb.`.

No rules:

    prometheus['rules_files'] = []

Custom list:

    prometheus['rules_files'] = ['/path/to/rules/*.rules', '/path/to/single/file.rules']

[alerting]: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
[recording]: https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/

