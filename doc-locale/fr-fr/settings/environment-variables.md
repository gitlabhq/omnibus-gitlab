---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Définition de variables d'environnement personnalisées"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si nécessaire, vous pouvez définir des variables d'environnement personnalisées à utiliser par Puma, Sidekiq, Rails et Rake via `/etc/gitlab/gitlab.rb`. Cela peut être utile dans les situations où vous devez utiliser un proxy pour accéder à Internet et avez besoin de cloner des dépôts hébergés en externe directement dans GitLab. Dans `/etc/gitlab/gitlab.rb`, fournissez un `gitlab_rails['env']` avec une valeur de hachage. Par exemple :

```ruby
gitlab_rails['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
#    "no_proxy" => ".yourdomain.com"  # Wildcard syntax if you need your internal domain to bypass proxy. Do not specify a port.
}
```

Vous pouvez également remplacer les variables d'environnement d'autres composants GitLab, ce qui peut être nécessaire si vous êtes derrière un proxy :

```ruby
# Needed for proxying Git clones
gitaly['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

gitlab_workhorse['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

gitlab_pages['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

# If you use the docker registry
registry['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}
```

GitLab tentera d'utiliser l'authentification HTTP de base lorsqu'un nom d'utilisateur et un mot de passe sont inclus dans l'URL du proxy.

Les paramètres de proxy utilisent la syntaxe `.` pour le globbing.

Les valeurs d'URL de proxy doivent généralement être `http://` uniquement, à moins que votre proxy ne dispose de son propre certificat SSL et que SSL soit activé. Cela signifie que, même pour la valeur `https_proxy`, vous devez généralement spécifier une valeur telle que `http://<USERNAME>:<PASSWORD>@example.com:8080`.

> [!note]
> La protection contre le rebinding DNS est désactivée lorsque la variable d'environnement HTTP_PROXY ou HTTPS_PROXY est définie et que le DNS du domaine ne peut pas être résolu.

## Application des modifications {#applying-the-changes}

Toute modification apportée aux variables d'environnement nécessite une reconfiguration pour prendre effet.

Effectuez une reconfiguration :

```shell
sudo gitlab-ctl reconfigure
```

## Variables d'environnement notables {#noteworthy-environment-variables}

### `TMPDIR` {#tmpdir}

Ruby et d'autres composants utilisent la variable d'environnement `TMPDIR` pour déterminer où stocker les fichiers temporaires. Par défaut, il s'agit de `/tmp`.

Vous devrez peut-être configurer un répertoire temporaire personnalisé si :

- Votre `/tmp` est monté en tant que `tmpfs` avec un espace limité.
- Les fichiers volumineux (tels que les objets LFS ou les artefacts CI) provoquent le remplissage de `/tmp`.
- Les [sites secondaires Geo](https://docs.gitlab.com/ee/administration/geo/) manquent d'espace dans `/tmp` lors de la réplication du stockage d'objets.

Pour configurer un répertoire temporaire personnalisé :

1. Créez le répertoire et définissez les permissions :

   ```shell
   sudo mkdir -p /var/opt/gitlab/tmp
   sudo chown git:git /var/opt/gitlab/tmp
   sudo chmod 700 /var/opt/gitlab/tmp
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` pour définir `TMPDIR` pour Rails et Workhorse :

   ```ruby
   gitlab_rails['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   gitlab_workhorse['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   ```

   > [!note]
   > Les deux valeurs **doivent** pointer vers le même répertoire. Lors du chargement d'artefacts CI/CD avec le stockage d'objets activé, Workhorse génère un fichier de métadonnées dans son `TMPDIR` et transmet le chemin à Rails. Rails valide que le fichier se trouve dans un répertoire autorisé (qui inclut son propre `TMPDIR`). Si ces valeurs diffèrent, les chargements d'artefacts échouent avec `400 Bad Request`.

1. Reconfigurer et redémarrer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

1. Vérifiez le paramètre :

   ```shell
   sudo gitlab-rails runner "puts ENV['TMPDIR']"
   ```

   La sortie doit afficher le chemin que vous avez configuré.

## Dépannage {#troubleshooting}

### Une variable d'environnement n'est pas définie {#an-environment-variable-is-not-being-set}

Vérifiez que vous n'avez pas plusieurs entrées pour le même `['env']`. La dernière remplacera les entrées précédentes. Dans cet exemple, `NTP_HOST` ne sera pas défini :

```ruby
gitlab_rails['env'] = { 'NTP_HOST' => "<DOMAIN_OF_NTP_SERVICE>" }

gitlab_rails['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}
```

### Les chargements d'artefacts CI/CD échouent avec `400 Bad Request` après la modification de `TMPDIR` {#cicd-artifact-uploads-fail-with-400-bad-request-after-changing-tmpdir}

Si les chargements d'artefacts CI/CD renvoient `400 Bad Request` avec `Content-Type: text/plain` après la configuration d'un [`TMPDIR` personnalisé](#tmpdir), la cause la plus probable est une discordance entre les valeurs `TMPDIR` pour Rails et Workhorse.

Pour résoudre ce problème :

1. Assurez-vous que les deux valeurs correspondent dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   gitlab_workhorse['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Vous pouvez confirmer la discordance en consultant les journaux de Workhorse pour l'ID de corrélation ayant échoué. Recherchez les entrées `metadata.gz` avec `local_temp_path` pointant vers un répertoire différent de votre `TMPDIR` configuré.

### Erreur : `Connection reset by peer` lors de la mise en miroir des dépôts {#error-connection-reset-by-peer-when-mirroring-repositories}

Si la valeur `no_proxy` inclut des numéros de port dans les URL, cela peut entraîner des échecs de résolution DNS. Supprimez les numéros de port des URL `no_proxy` pour résoudre ce problème.
