---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Artifact Registry
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!warning]
> Artifact Registry est une version expérimentale. Le service lui-même s'exécute uniquement sur GitLab.com et ces paramètres sont susceptibles d'être modifiés. Ils existent afin qu'une instance GitLab Self-Managed puisse se connecter à ce service dans le cadre d'un déploiement hybride. Ne considérez pas Artifact Registry comme généralement disponible pour GitLab Self-Managed.

Artifact Registry s'exécute en tant que service distinct. Le package Linux ne l'installe ni ne le package. Ces paramètres configurent GitLab Rails pour se connecter à un service Artifact Registry que vous exécutez vous-même. Utilisez-les pour les déploiements hybrides, où GitLab Rails s'exécute sur une installation de package Linux et Artifact Registry s'exécute ailleurs.

## Configurer la connexion {#configure-the-connection}

Pour pointer GitLab vers un service Artifact Registry, modifiez `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_rails['artifact_registry']['api_url'] = 'https://artifact-registry.example.com'
```

Reconfigurez ensuite GitLab :

```shell
sudo gitlab-ctl reconfigure
```

Cette opération intègre la clé `artifact_registry.api_url` dans `gitlab.yml`. Lorsque `api_url` n'est pas défini, GitLab n'affiche aucune section `artifact_registry` et ne se connecte à aucun service Artifact Registry.

## Configurer le jeton de service {#configure-the-service-token}

L'API interne d'Artifact Registry s'authentifie à l'aide d'un jeton de service partagé. Le fichier qui le contient est fourni par l'opérateur. Le package Linux ne le crée, ne le génère ni ne le gère.

Écrivez le jeton que le service Artifact Registry accepte dans le fichier, puis limitez l'accès à celui-ci :

```shell
sudo mkdir -p /etc/gitlab/artifact-registry
sudo install -m 0400 -o git -g root /dev/stdin /etc/gitlab/artifact-registry/.gitlab_artifact_registry_secret <<< 'your-service-token'
```

`/etc/gitlab` est accessible en lecture par tous, donc une simple copie laisse le jeton lisible par tous les utilisateurs locaux. Le fichier doit rester lisible par l'utilisateur `git`. Un fichier accessible uniquement par root passe `gitlab-ctl reconfigure`, qui s'exécute en tant que `root`, mais interrompt silencieusement le chemin de service de l'application, qui s'exécute en tant que `git`.

Pointez ensuite GitLab vers celui-ci :

```ruby
gitlab_rails['artifact_registry']['service_token_file'] = '/etc/gitlab/artifact-registry/.gitlab_artifact_registry_secret'
```

Après la reconfiguration, GitLab intègre le chemin du fichier de jeton dans `gitlab.yml` sous `artifact_registry.service_token.secret_file`. Lorsque le fichier de jeton n'est pas défini, GitLab n'affiche que `api_url` et le chemin de service reste fermé jusqu'à ce que vous configuriez le jeton.
