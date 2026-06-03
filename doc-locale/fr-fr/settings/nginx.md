---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres NGINX
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette page fournit des informations de configuration destinées aux administrateurs et aux ingénieurs DevOps qui configurent NGINX pour les installations GitLab. Elle comprend des instructions essentielles pour optimiser les performances et la sécurité, spécifiques à NGINX groupé (package Linux), aux charts Helm ou aux configurations personnalisées.

## Paramètres NGINX spécifiques aux services {#service-specific-nginx-settings}

Pour configurer les paramètres NGINX pour différents services, modifiez le fichier `gitlab.rb`.

> [!warning]
> Une configuration incorrecte ou incompatible peut rendre le service indisponible.

Utilisez les clés `nginx['<setting>']` pour configurer les paramètres de l'application GitLab Rails. GitLab fournit des clés similaires pour d'autres services comme `pages_nginx` et `registry_nginx`. Les configurations pour `nginx` sont également disponibles pour ces paramètres `<service_nginx>`, et partagent les mêmes valeurs par défaut que GitLab NGINX.

Lorsque vous modifiez le fichier `gitlab.rb`, configurez les paramètres NGINX pour chaque service séparément. Les paramètres spécifiés avec `nginx['foo']` ne sont pas répliqués vers les configurations NGINX spécifiques aux services (comme `registry_nginx['foo']`). Par exemple, pour configurer la redirection HTTP vers HTTPS pour GitLab et Registry, ajoutez les paramètres suivants à `gitlab.rb` :

```ruby
nginx['redirect_http_to_https'] = true
registry_nginx['redirect_http_to_https'] = true
```

## Activer HTTPS {#enable-https}

Par défaut, les installations par package Linux n'utilisent pas HTTPS. Pour activer HTTPS pour `gitlab.example.com` :

- [Utiliser Let's Encrypt pour un HTTPS gratuit et automatisé](ssl/_index.md#enable-the-lets-encrypt-integration).
- [Configurer manuellement HTTPS avec vos propres certificats](ssl/_index.md#configure-https-manually).

Si vous utilisez un proxy, un équilibreur de charge ou un autre dispositif externe pour terminer SSL pour le nom d'hôte GitLab, consultez [Terminaison SSL externe, proxy et équilibreur de charge](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination).

## Modifier les en-têtes de proxy par défaut {#change-the-default-proxy-headers}

Par défaut, lorsque vous spécifiez `external_url`, une installation par package Linux définit des en-têtes de proxy NGINX adaptés à la plupart des environnements.

Par exemple, si vous spécifiez le schéma `https` dans le `external_url`, une installation par package Linux définit :

```plaintext
"X-Forwarded-Proto" => "https",
"X-Forwarded-Ssl" => "on"
```

Si votre instance GitLab est dans une configuration plus complexe, par exemple derrière un proxy inverse, vous devrez peut-être ajuster les en-têtes de proxy pour éviter des erreurs telles que :

- `The change you wanted was rejected`
- `Can't verify CSRF token authenticity Completed 422 Unprocessable`

Pour remplacer les en-têtes par défaut :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['proxy_set_headers'] = {
     "X-Forwarded-Proto" => "http",
     "CUSTOM_HEADER" => "VALUE"
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Vous pouvez spécifier n'importe quel en-tête pris en charge par NGINX.

## Configurer les proxies de confiance GitLab et le module NGINX `real_ip` {#configure-gitlab-trusted-proxies-and-nginx-real_ip-module}

Par défaut, NGINX et GitLab enregistrent l'adresse IP du client connecté.

Si GitLab est derrière un proxy inverse, vous ne souhaiterez peut-être pas que l'adresse IP du proxy apparaisse comme adresse client.

Pour configurer NGINX afin qu'il utilise une adresse différente, ajoutez votre proxy inverse à la liste `real_ip_trusted_addresses` :

```ruby
# Each address is added to the NGINX config as 'set_real_ip_from <address>;'
nginx['real_ip_trusted_addresses'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
# Other real_ip config options
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
```

Pour une description de ces options, consultez la [documentation du module NGINX `realip`](http://nginx.org/en/docs/http/ngx_http_realip_module.html).

Par défaut, les installations par package Linux utilisent les adresses IP dans `real_ip_trusted_addresses` comme proxies de confiance GitLab. La configuration des proxies de confiance empêche que les utilisateurs soient répertoriés comme connectés depuis ces adresses IP.

Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

## Configurer le protocole PROXY {#configure-the-proxy-protocol}

Pour utiliser un proxy comme HAProxy devant GitLab avec le [protocole PROXY](https://www.haproxy.org/download/3.1/doc/proxy-protocol.txt) :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Enable termination of ProxyProtocol by NGINX
   nginx['proxy_protocol'] = true
   # Configure trusted upstream proxies. Required if `proxy_protocol` is enabled.
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Après avoir activé ce paramètre, NGINX accepte uniquement le trafic de protocole PROXY sur ces listeners. Ajustez les autres environnements que vous pourriez avoir, comme les vérifications de surveillance.

## Utiliser un serveur web non groupé {#use-a-non-bundled-web-server}

> [!note]
> GitLab fournit des informations sur la configuration d'un serveur web non groupé à titre indicatif uniquement. Le dépannage d'un composant non groupé est considéré comme [hors du périmètre de support](https://about.gitlab.com/support/statement-of-support/#out-of-scope-for-all-self-managed-and-saas-users). Si vous avez des questions ou des problèmes lors de l'utilisation d'un serveur web non groupé, consultez la documentation du serveur web non groupé.

Par défaut, le package Linux installe GitLab avec NGINX groupé. Les installations par package Linux autorisent l'accès du serveur web via l'utilisateur `gitlab-www`, qui appartient au groupe du même nom. Pour autoriser un serveur web externe à accéder à GitLab, ajoutez l'utilisateur du serveur web externe au groupe `gitlab-www`.

Pour utiliser un autre serveur web comme Apache ou une installation NGINX existante :

1. Désactivez NGINX groupé :

   Dans `/etc/gitlab/gitlab.rb`, définissez :

   ```ruby
   nginx['enable'] = false
   ```

1. Définissez le nom d'utilisateur du serveur web non groupé :

   Les installations par package Linux n'ont pas de paramètre par défaut pour l'utilisateur du serveur web externe. Vous devez le spécifier dans la configuration. Par exemple :

   - Debian/Ubuntu : L'utilisateur par défaut est `www-data` pour Apache et NGINX.
   - RHEL/CentOS : L'utilisateur NGINX est `nginx`.

   Installez Apache ou NGINX avant de continuer, afin que l'utilisateur du serveur web soit créé. Sinon, l'installation du package Linux échoue lors de la reconfiguration.

   Si l'utilisateur du serveur web est `www-data`, dans `/etc/gitlab/gitlab.rb`, définissez :

   ```ruby
   web_server['external_users'] = ['www-data']
   ```

   Ce paramètre est un tableau, vous pouvez donc spécifier plusieurs utilisateurs à ajouter au groupe `gitlab-www`.

   Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.

   Si vous utilisez SELinux et que votre serveur web fonctionne sous un profil SELinux restreint, vous devrez peut-être [configurer les permissions SELinux](https://gitlab.com/gitlab-org/gitlab-recipes/-/blob/master/web-server/apache/README.md#selinux-modifications).

   Assurez-vous que l'utilisateur du serveur web dispose des permissions correctes sur tous les répertoires utilisés par le serveur web externe. Sinon, vous pourriez recevoir des erreurs `failed (XX: Permission denied) while reading upstream`.

1. Ajoutez le serveur web non groupé à la liste des proxies de confiance :

   Les installations par package Linux utilisent généralement par défaut la liste des proxies de confiance issue de la configuration du module `real_ip` pour le NGINX groupé.

   Pour les serveurs web non groupés, configurez la liste directement. Incluez l'adresse IP de votre serveur web s'il ne se trouve pas sur la même machine que GitLab. Sinon, les utilisateurs semblent être connectés depuis l'adresse IP de votre serveur web.

   ```ruby
   gitlab_rails['trusted_proxies'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
   ```

1. Facultatif. Si vous utilisez Apache, définissez les paramètres de GitLab Workhorse :

   Apache ne peut pas se connecter à un socket UNIX et doit se connecter à un port TCP. Pour permettre à GitLab Workhorse d'écouter sur TCP (port 8181 par défaut), modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_workhorse['listen_network'] = "tcp"
   gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
   ```

   Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.

1. Téléchargez la configuration correcte du serveur web :

   Accédez au [dépôt GitLab](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/support/nginx) et téléchargez la configuration requise. Sélectionnez le fichier de configuration approprié pour servir GitLab avec ou sans SSL. Vous devrez peut-être modifier :

   - La valeur de `YOUR_SERVER_FQDN` par votre FQDN.
   - Si vous utilisez SSL, l'emplacement de vos clés SSL.
   - L'emplacement de vos fichiers journaux.

## Options de configuration NGINX {#nginx-configuration-options}

GitLab fournit diverses options de configuration pour personnaliser le comportement de NGINX selon vos besoins spécifiques. Utilisez ces éléments de référence pour affiner votre configuration NGINX et optimiser les performances et la sécurité de GitLab.

### Définir les adresses d'écoute NGINX {#set-the-nginx-listen-addresses}

Par défaut, NGINX accepte les connexions entrantes sur toutes les adresses IPv4 locales.

Pour modifier la liste des adresses :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Listen on all IPv4 and IPv6 addresses
   nginx['listen_addresses'] = ["0.0.0.0", "[::]"]
   registry_nginx['listen_addresses'] = ['*', '[::]']
   pages_nginx['listen_addresses'] = ['*', '[::]']
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

### Définir le port d'écoute NGINX {#set-the-nginx-listen-port}

Par défaut, NGINX écoute sur le port spécifié dans `external_url` ou utilise le port standard (80 pour HTTP, 443 pour HTTPS). Si vous exécutez GitLab derrière un proxy inverse, vous pouvez remplacer le port d'écoute.

Pour modifier le port d'écoute :

1. Modifiez `/etc/gitlab/gitlab.rb`. Par exemple, pour utiliser le port 8081 :

   ```ruby
   nginx['listen_port'] = 8081
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

### Modifier le niveau de verbosité des journaux NGINX {#change-the-verbosity-level-of-nginx-logs}

Par défaut, NGINX consigne les journaux au niveau de verbosité `error`.

Pour modifier le niveau de journalisation :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['error_log_level'] = "debug"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Pour les valeurs valides du niveau de journalisation, consultez la [directive 'error_log'](https://nginx.org/en/docs/ngx_core_module.html#error_log).

### Définir l'en-tête Referrer-Policy {#set-the-referrer-policy-header}

Par défaut, GitLab définit l'en-tête `Referrer-Policy` à `strict-origin-when-cross-origin` sur toutes les réponses. Ce paramètre oblige le client à :

- Envoyer l'URL complète comme référent pour les requêtes de même origine.
- Envoyer uniquement l'origine pour les requêtes d'origine croisée.

Pour modifier cet en-tête :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['referrer_policy'] = 'same-origin'
   ```

   Pour désactiver cet en-tête et utiliser le paramètre par défaut du client :

   ```ruby
   nginx['referrer_policy'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

> [!warning]
> Définir cette valeur à `origin` ou `no-referrer` interrompt les fonctionnalités GitLab qui nécessitent l'URL de référent complète.

Pour plus d'informations, consultez la [spécification Referrer Policy](https://www.w3.org/TR/referrer-policy/).

### En-tête Cross-Origin-Resource-Policy et diagrammes Mermaid {#cross-origin-resource-policy-header-and-mermaid-diagrams}

Si vous configurez un en-tête `Cross-Origin-Resource-Policy` (CORP) avec la valeur `same-site` ou `same-origin`, les diagrammes Mermaid échouent silencieusement à s'afficher.

Par exemple :

```ruby
nginx['custom_gitlab_server_config'] = "add_header Cross-Origin-Resource-Policy same-site;"
```

L'iframe sandbox Mermaid omet intentionnellement l'attribut sandbox `allow-same-origin`. Cela entraîne l'attribution d'une origine nulle à l'iframe. Les navigateurs bloquent les chargements de ressources à origine nulle lorsque CORP est défini sur `same-site` ou `same-origin`, car null ne satisfait aucune des deux politiques.

Pour permettre le rendu des diagrammes Mermaid, utilisez `cross-origin` :

```ruby
nginx['custom_gitlab_server_config'] = "add_header Cross-Origin-Resource-Policy cross-origin;"
```

> [!warning]
> `cross-origin` est moins restrictif que `same-site` ou `same-origin`. Vérifiez vos exigences de sécurité avant d'utiliser ce paramètre.

### Désactiver la compression Gzip {#disable-gzip-compression}

Par défaut, GitLab active la compression Gzip pour les données textuelles de plus de 10 240 octets. Pour désactiver la compression Gzip :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['gzip_enabled'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

> [!note]
> Le paramètre `gzip` s'applique uniquement à l'application principale GitLab, pas aux autres services.

### Désactiver la mise en mémoire tampon des requêtes proxy {#disable-proxy-request-buffering}

Pour désactiver la mise en mémoire tampon des requêtes pour des emplacements spécifiques :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.
1. Rechargez la configuration NGINX de manière progressive :

   ```shell
   sudo gitlab-ctl hup nginx
   ```

Pour plus d'informations sur la commande `hup`, consultez la [documentation NGINX](https://nginx.org/en/docs/control.html).

### Configurer `robots.txt` {#configure-robotstxt}

Pour configurer un fichier [`robots.txt`](https://www.robotstxt.org/robotstxt.html) personnalisé pour votre instance :

1. Créez votre fichier `robots.txt` personnalisé et notez son chemin.
1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['custom_gitlab_server_config'] = "\nlocation =/robots.txt { alias /path/to/custom/robots.txt; }\n"
   ```

   Remplacez `/path/to/custom/robots.txt` par le chemin réel de votre fichier `robots.txt` personnalisé.

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Cette configuration ajoute un [paramètre NGINX personnalisé](#insert-custom-nginx-settings-into-the-gitlab-server-block) pour servir votre fichier `robots.txt` personnalisé.

### Insérer des paramètres NGINX personnalisés dans le bloc serveur GitLab {#insert-custom-nginx-settings-into-the-gitlab-server-block}

Pour ajouter des paramètres personnalisés au bloc `server` NGINX pour GitLab :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Example: block raw file downloads from a specific repository
   nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Cette commande insère la chaîne définie à la fin du bloc `server` dans `/var/opt/gitlab/nginx/conf/service_conf/gitlab-rails.conf`.

> [!warning]
> Les paramètres personnalisés peuvent entrer en conflit avec des paramètres définis ailleurs dans votre fichier `gitlab.rb`.

#### Désactiver le serveur par défaut {#disable-the-default-server}

Par défaut, le NGINX groupé inclut `default_server` dans les directives `listen` du bloc serveur GitLab. Cette configuration amène NGINX à utiliser ce bloc serveur comme valeur par défaut pour toutes les requêtes qui ne correspondent pas à d'autres blocs serveur.

Si vous devez ajouter votre propre bloc serveur personnalisé avec `default_server` (par exemple, lors de l'utilisation de `nginx['custom_gitlab_server_config']`), vous devez désactiver le serveur par défaut dans la configuration GitLab :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['default_server_enabled'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Cette approche supprime `default_server` des directives `listen` afin que vous puissiez définir votre propre bloc serveur par défaut.

#### Notes {#notes}

- Si vous ajoutez un nouvel emplacement, vous devrez peut-être inclure :

  ```conf
  proxy_cache off;
  proxy_http_version 1.1;
  proxy_pass http://gitlab-workhorse;
  ```

  Sans ces éléments, tout sous-emplacement pourrait renvoyer une erreur 404.

- Vous ne pouvez pas ajouter l'emplacement racine `/` ni l'emplacement `/assets`, car ils existent déjà dans `gitlab-rails.conf`.

### Insérer des paramètres personnalisés dans la configuration NGINX {#insert-custom-settings-into-the-nginx-configuration}

Pour ajouter des paramètres personnalisés à la configuration NGINX :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Example: include a directory to scan for additional config files
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/sites-enabled/*.conf;"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Cette commande insère la chaîne définie à la fin du bloc `http` dans `/var/opt/gitlab/nginx/conf/nginx.conf`.

Par exemple, pour créer et activer des blocs serveur personnalisés :

1. Créez des blocs serveur personnalisés dans le répertoire `/etc/gitlab/nginx/sites-available`.
1. Créez le répertoire `/etc/gitlab/nginx/sites-enabled` s'il n'existe pas.
1. Pour activer un bloc serveur personnalisé, créez un lien symbolique :

   ```shell
   sudo ln -s /etc/gitlab/nginx/sites-available/example.conf /etc/gitlab/nginx/sites-enabled/example.conf
   ```

1. Rechargez la configuration NGINX :

   ```shell
   sudo gitlab-ctl hup nginx
   ```

   Vous pouvez également redémarrer NGINX :

   ```shell
   sudo gitlab-ctl restart nginx
   ```

Vous pouvez ajouter des domaines pour les blocs serveur [comme nom alternatif](ssl/_index.md#add-alternative-domains-to-the-certificate) au certificat SSL Let's Encrypt généré.

Les paramètres NGINX personnalisés dans le répertoire `/etc/gitlab/` sont sauvegardés dans `/etc/gitlab/config_backup/` lors d'une mise à niveau et lorsque `sudo gitlab-ctl backup-etc` est exécuté manuellement.

### Configurer des pages d'erreur personnalisées {#configure-custom-error-pages}

Pour modifier le texte des pages d'erreur GitLab par défaut :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['custom_error_pages'] = {
    '404' => {
      'title' => 'Example title',
      'header' => 'Example header',
      'message' => 'Example message'
    }
   }
   ```

   Cet exemple modifie la page d'erreur 404 par défaut. Vous pouvez utiliser ce format pour tout code d'erreur HTTP valide, tel que 404 ou 502.

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

Le résultat pour la page d'erreur 404 ressemblerait à ceci :

![page d'erreur 404 personnalisée](img/error_page_example.png)

### Utiliser une installation Passenger et NGINX existante {#use-an-existing-passenger-and-nginx-installation}

Vous pouvez héberger GitLab avec une installation Passenger et NGINX existante tout en continuant à utiliser les packages Linux pour les mises à jour et l'installation.

Si vous désactivez NGINX, vous ne pouvez pas accéder aux autres services inclus dans une installation par package Linux, sauf si vous les ajoutez manuellement à `nginx.conf`.

#### Configuration {#configuration}

Pour configurer GitLab avec une installation Passenger et NGINX existante :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Define the external url
   external_url 'http://git.example.com'

   # Disable the built-in NGINX
   nginx['enable'] = false

   # Disable the built-in Puma
   puma['enable'] = false

   # Set the internal API URL
   gitlab_rails['internal_api_url'] = 'http://git.example.com'

   # Define the web server process user (ubuntu/nginx)
   web_server['external_users'] = ['www-data']
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

#### Configurer l'hôte virtuel (bloc serveur) {#configure-the-virtual-host-server-block}

Dans votre installation Passenger/NGINX personnalisée :

1. Créez un nouveau fichier de configuration de site avec le contenu suivant :

   ```plaintext
   upstream gitlab-workhorse {
    server unix://var/opt/gitlab/gitlab-workhorse/sockets/socket fail_timeout=0;
   }

   server {
    listen *:80;
    server_name git.example.com;
    server_tokens off;
    root /opt/gitlab/embedded/service/gitlab-rails/public;

    client_max_body_size 250m;

    access_log  /var/log/gitlab/nginx/gitlab_access.log;
    error_log   /var/log/gitlab/nginx/gitlab_error.log;

    # Ensure Passenger uses the bundled Ruby version
    passenger_ruby /opt/gitlab/embedded/bin/ruby;

    # Correct the $PATH variable to included packaged executables
    passenger_env_var PATH "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/usr/local/bin:/usr/bin:/bin";

    # Make sure Passenger runs as the correct user and group to
    # prevent permission issues
    passenger_user git;
    passenger_group git;

    # Enable Passenger & keep at least one instance running at all times
    passenger_enabled on;
    passenger_min_instances 1;

    location ~ ^/[\w\.-]+/[\w\.-]+/(info/refs|git-upload-pack|git-receive-pack)$ {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    location ~ ^/[\w\.-]+/[\w\.-]+/repository/archive {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    location ~ ^/api/v3/projects/.*/repository/archive {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ ^/[\w\.-]+/[\w\.-]+/builds/download {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ /ci/api/v1/builds/[0-9]+/artifacts {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ /api/v4/jobs/[0-9]+/artifacts {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }


    # For protocol upgrades from HTTP/1.0 to HTTP/1.1 we need to provide Host header if its missing
    if ($http_host = "") {
    # use one of values defined in server_name
      set $http_host_with_default "git.example.com";
    }

    if ($http_host != "") {
      set $http_host_with_default $http_host;
    }

    location @gitlab-workhorse {

      ## https://github.com/gitlabhq/gitlabhq/issues/694
      ## Some requests take more than 30 seconds.
      proxy_read_timeout      3600;
      proxy_connect_timeout   300;
      proxy_redirect          off;

      # Do not buffer Git HTTP responses
      proxy_buffering off;

      proxy_set_header    Host                $http_host_with_default;
      proxy_set_header    X-Real-IP           $remote_addr;
      proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
      proxy_set_header    X-Forwarded-Proto   $scheme;

      proxy_http_version 1.1;
      proxy_pass http://gitlab-workhorse;

      ## The following settings only work with NGINX 1.7.11 or newer
      #
      ## Pass chunked request bodies to gitlab-workhorse as-is
      # proxy_request_buffering off;
      # proxy_http_version 1.1;
    }

    ## Enable gzip compression as per rails guide:
    ## http://guides.rubyonrails.org/asset_pipeline.html#gzip-compression
    ## WARNING: If you are using relative urls remove the block below
    ## See config/application.rb under "Relative url support" for the list of
    ## other files that need to be changed for relative url support
    location ~ ^/(assets)/ {
      root /opt/gitlab/embedded/service/gitlab-rails/public;
      gzip_static on; # to serve pre-gzipped version
      expires max;
      add_header Cache-Control public;
    }

    error_page 502 /502.html;
   }
   ```

   Remplacez `git.example.com` par l'URL de votre serveur.

Si vous recevez une erreur 403 Forbidden, assurez-vous que Passenger est activé dans `/etc/nginx/nginx.conf` :

1. Décommentez cette ligne :

   ```plaintext
   # include /etc/nginx/passenger.conf;
   ```

1. Rechargez la configuration NGINX :

   ```shell
   sudo service nginx reload
   ```

### Configurer la surveillance du statut NGINX {#configure-nginx-status-monitoring}

Par défaut, GitLab configure un point de terminaison de vérification de l'état NGINX à `127.0.0.1:8060/nginx_status` pour surveiller l'état de votre serveur NGINX. Lorsque le module VTS (Virtual host Traffic Status) est activé (par défaut), ce port sert également des métriques Prometheus à `127.0.0.1:8060/metrics`.

Le point de terminaison affiche les informations suivantes :

```plaintext
Active connections: 1
server accepts handled requests
18 18 36
Reading: 0 Writing: 1 Waiting: 0
```

- Connexions actives : Total des connexions ouvertes.
- Trois chiffres indiquant :
  - Toutes les connexions acceptées.
  - Toutes les connexions traitées.
  - Nombre total de requêtes traitées.
- Lecture : NGINX lit les en-têtes de requête.
- Écriture : NGINX lit les corps de requête, traite les requêtes ou écrit des réponses à un client.
- Attente : Connexions keep-alive. Ce nombre dépend de la directive `keepalive_timeout`.

#### Configurer les options de statut NGINX {#configure-nginx-status-options}

Pour configurer les options de statut NGINX :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['status'] = {
    "listen_addresses" => ["127.0.0.1"],
    "fqdn" => "dev.example.com",
    "options" => {
      "access_log" => "off", # Disable logs for stats
      "allow" => "127.0.0.1", # Only allow access from localhost
      "deny" => "all" # Deny access to anyone else
    }
   }
   ```

> [!note]
> Lorsque VTS est activé, n'incluez pas `"stub_status" => "on"` dans les options. Ce paramètre s'applique à tous les points de terminaison et entraîne le renvoi par `/metrics` de la sortie `nginx_status` de base au lieu des métriques Prometheus.

   Pour désactiver VTS et n'utiliser que les métriques `nginx_status` de base :

   ```ruby
   nginx['status']['vts_enable'] = false
   ```

   Pour désactiver le point de terminaison de statut NGINX :

   ```ruby
   nginx['status'] = {
    'enable' => false
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations) pour que les modifications prennent effet.

#### Configurer des métriques avancées avec le module VTS {#configure-advanced-metrics-with-vts-module}

GitLab inclut le module NGINX VTS (Virtual host Traffic Status) pour fournir des métriques de performance supplémentaires, notamment les percentiles de latence.

Avant d'activer le module VTS avec des intervalles d'histogramme, tenez compte de ces impacts :

- L'utilisation de la mémoire augmente pour stocker les données de métriques. L'impact évolue en fonction du nombre d'hôtes virtuels et du volume de trafic.
- Le calcul des métriques d'histogramme pour chaque requête consomme une petite quantité de CPU.
- Si vous collectez ces métriques dans Prometheus, vous avez besoin d'un espace de stockage supplémentaire.

Pour les installations à fort trafic, surveillez les ressources système après l'activation de ces métriques pour vous assurer que les performances restent dans des limites acceptables.

Pour activer les métriques de latence avancées :

1. Ajoutez la configuration suivante à `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['custom_gitlab_server_config'] = "vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;"
   ```

   Ou créez un fichier de configuration NGINX personnalisé :

   ```shell
   sudo mkdir -p /etc/gitlab/nginx/conf.d/
   sudo vim /etc/gitlab/nginx/conf.d/vts-custom.conf
   ```

1. Ajoutez ces paramètres pour activer les intervalles d'histogramme et le filtrage :

   ```nginx
   vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;
   vhost_traffic_status_filter_by_host on;
   vhost_traffic_status_filter on;
   vhost_traffic_status_filter_by_set_key $server_name server::*;
   ```

1. Pour configurer GitLab afin d'inclure vos paramètres personnalisés, ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/conf.d/vts-custom.conf;"
   ```

1. Reconfigurez et redémarrez NGINX :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart nginx
   ```

Après l'activation de ces paramètres, vous pouvez utiliser des requêtes Prometheus pour surveiller diverses métriques de latence :

```plaintext
# Average response time
rate(nginx_vts_server_request_seconds_total[5m]) / rate(nginx_vts_server_requests_total{code=~"2xx|3xx|4xx|5xx"}[5m])

# P90 latency
histogram_quantile(0.90, rate(nginx_vts_server_request_duration_seconds_bucket[5m]))

# P99 latency
histogram_quantile(0.99, rate(nginx_vts_server_request_duration_seconds_bucket[5m]))

# Average upstream response time
rate(nginx_vts_upstream_response_seconds_total[5m]) / rate(nginx_vts_upstream_requests_total{code=~"2xx|3xx|4xx|5xx"}[5m])

# P90 upstream latency
histogram_quantile(0.90, rate(nginx_vts_upstream_response_duration_seconds_bucket[5m]))

# P99 upstream latency
histogram_quantile(0.99, rate(nginx_vts_upstream_response_duration_seconds_bucket[5m]))
```

Pour les métriques spécifiques à GitLab Workhorse, vous pouvez utiliser :

```plaintext
# 90th percentile upstream latency for GitLab Workhorse
histogram_quantile(0.90, rate(nginx_vts_upstream_response_duration_seconds_bucket{upstream="gitlab-workhorse"}[5m]))

# Average upstream response time for GitLab Workhorse
rate(nginx_vts_upstream_response_seconds_total{upstream="gitlab-workhorse"}[5m]) /
rate(nginx_vts_upstream_requests_total{upstream="gitlab-workhorse",code=~"2xx|3xx|4xx|5xx"}[5m])
```

#### Configurer les permissions utilisateur pour les téléversements {#configure-user-permissions-for-uploads}

Pour vous assurer que les téléversements des utilisateurs sont accessibles, ajoutez votre utilisateur NGINX (généralement `www-data`) au groupe `gitlab-www` :

```shell
sudo usermod -aG gitlab-www www-data
```

### Modèles {#templates}

Les fichiers de configuration sont similaires à la [configuration NGINX GitLab groupée](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-rails.conf.erb), avec ces différences :

- La configuration Passenger est utilisée à la place de Puma.
- HTTPS n'est pas activé par défaut, mais vous pouvez l'activer.

Après avoir apporté des modifications à la configuration NGINX :

- Pour les systèmes basés sur Debian, redémarrez NGINX :

  ```shell
  sudo service nginx restart
  ```

- Pour les autres systèmes, consultez la documentation de votre système d'exploitation pour connaître la commande correcte permettant de redémarrer NGINX.
