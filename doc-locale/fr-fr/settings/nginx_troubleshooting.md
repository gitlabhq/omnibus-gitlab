---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de NGINX
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lors de la [configuration de NGINX](nginx.md), vous pouvez rencontrer les problèmes suivants.

## Erreur : `400 Bad Request: too many Host headers` {#error-400-bad-request-too-many-host-headers}

La solution de contournement consiste à vous assurer que vous n'avez pas la configuration `proxy_set_header` dans les paramètres `nginx['custom_gitlab_server_config']`. Utilisez plutôt la configuration [`proxy_set_headers`](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination) dans votre fichier `gitlab.rb`.

## Erreur : `Received fatal alert: handshake_failure` {#error-received-fatal-alert-handshake_failure}

Vous pourriez obtenir une erreur indiquant :

```plaintext
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
```

Ce problème survient lorsque vous utilisez un client IDE basé sur Java plus ancien pour interagir avec votre instance GitLab. Ces IDE peuvent utiliser le protocole TLS 1, que les installations de packages Linux ne prennent pas en charge par défaut.

Pour résoudre ce problème, mettez à niveau les chiffrements sur votre serveur, comme l'utilisateur dans le [ticket 624](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/624#note_299061).

S'il n'est pas possible d'apporter cette modification au serveur, vous pouvez revenir à l'ancien comportement en modifiant les valeurs dans votre `/etc/gitlab/gitlab.rb` :

```ruby
nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3"
```

## Incompatibilité entre la clé privée et le certificat {#mismatch-between-private-key-and-certificate}

Dans les [journaux NGINX](https://docs.gitlab.com/administration/logs/#nginx-logs), vous pourriez trouver :

```plaintext
x509 certificate routines:X509_check_private_key:key values mismatch)
```

Ce problème survient lorsqu'il y a une incompatibilité entre votre clé privée et votre certificat.

Pour résoudre ce problème, associez la bonne clé privée à votre certificat :

1. Pour vous assurer que vous disposez de la bonne clé et du bon certificat, vérifiez si les moduli de la clé privée et du certificat correspondent :

   ```shell
   /opt/gitlab/embedded/bin/openssl rsa -in /etc/gitlab/ssl/gitlab.example.com.key -noout -modulus | /opt/gitlab/embedded/bin/openssl sha256

   /opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/ssl/gitlab.example.com.crt -noout -modulus| /opt/gitlab/embedded/bin/openssl sha256
   ```

1. Après avoir vérifié qu'ils correspondent, reconfigurez et rechargez NGINX :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

## `Request Entity Too Large` {#request-entity-too-large}

Dans les [journaux NGINX](https://docs.gitlab.com/administration/logs/#nginx-logs), vous pourriez trouver :

```plaintext
Request Entity Too Large
```

Cette erreur survient lorsque votre requête dépasse la taille de corps maximale autorisée. Si vous avez récemment augmenté la [taille d'importation maximale](https://docs.gitlab.com/administration/settings/import_and_export_settings/#max-import-size), vous devez également mettre à jour la configuration NGINX.

Pour résoudre ce problème, configurez la directive [`client_max_body_size`](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size) :

1. Modifiez `/etc/gitlab/gitlab.rb` et augmentez la valeur pour la taille de corps maximale du client :

   ```ruby
   nginx['client_max_body_size'] = '250m'
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation).
1. [`HUP`](https://nginx.org/en/docs/control.html) NGINX pour qu'il se recharge avec la configuration mise à jour de manière progressive :

   ```shell
   sudo gitlab-ctl hup nginx
   ```

Pour les installations Kubernetes, configurez [`proxyBodySize`](https://docs.gitlab.com/charts/charts/gitlab/webservice/#proxybodysize) plutôt que `client_max_body_size`.

## Avertissement d'analyse de sécurité : `NGINX HTTP Server Detection` {#security-scan-warning-nginx-http-server-detection}

Ce problème survient lorsque certains scanners de sécurité détectent l'en-tête HTTP `Server: nginx`. La plupart des scanners ayant cette alerte la classifient avec une gravité `Low` ou `Info`. Par exemple, consultez [Nessus](https://www.tenable.com/plugins/nessus/106375).

Vous devriez ignorer cet avertissement, car l'avantage de supprimer l'en-tête est faible, et sa présence [contribue au projet NGINX dans les statistiques d'utilisation](https://trac.nginx.org/nginx/ticket/1644).

La solution de contournement consiste à désactiver l'en-tête en utilisant `hide_server_tokens` :

1. Modifiez `/etc/gitlab/gitlab.rb` et définissez la valeur :

   ```ruby
   nginx['hide_server_tokens'] = 'on'
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation).
1. [`HUP`](https://nginx.org/en/docs/control.html) NGINX pour qu'il se recharge avec la configuration mise à jour de manière progressive :

   ```shell
   sudo gitlab-ctl hup nginx
   ```

## Branche introuvable lors de l'utilisation de Web IDE et d'un NGINX externe {#branch-not-found-when-using-web-ide-and-external-nginx}

Vous pourriez obtenir une erreur indiquant :

```plaintext
Branch 'branch_name' was not found in this project's repository
```

Ce problème survient lorsqu'il y a une barre oblique finale dans `proxy_pass` dans votre fichier de configuration NGINX.

Pour le résoudre :

1. Modifiez votre fichier de configuration NGINX afin qu'il n'y ait pas de barre oblique finale dans `proxy_pass` :

   ```plaintext
   proxy_pass https://1.2.3.4;
   ```

1. Redémarrez NGINX :

   ```shell
   sudo systemctl restart nginx
   ```

## Erreur : `worker_connections are not enough` {#error-worker_connections-are-not-enough}

Vous pourriez obtenir des erreurs `502` de GitLab et trouver les éléments suivants dans les [journaux NGINX](https://docs.gitlab.com/administration/logs/#nginx-logs) :

```plaintext
worker_connections are not enough
```

Ce problème survient lorsque les connexions worker sont définies sur une valeur trop faible.

Pour le résoudre, configurez les connexions worker NGINX sur une valeur plus élevée :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab['nginx']['worker_connections'] = 10240
   ```

   10 240 connexions est [la valeur par défaut](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/374b34e2bdc4bccb73665e0dc856ae32d6082d77/files/gitlab-cookbooks/gitlab/attributes/default.rb#L883).

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
