---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Modification des paramètres du fichier de configuration
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Certaines fonctionnalités de GitLab peuvent être personnalisées via [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example). Si vous souhaitez modifier un paramètre `gitlab.yml` pour une installation de package Linux, vous devez le faire via `/etc/gitlab/gitlab.rb`. La traduction fonctionne comme suit. Pour obtenir la liste complète des options disponibles, consultez [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

Toutes les options du modèle répertoriées dans `/etc/gitlab/gitlab.rb` sont disponibles par défaut.

Dans `gitlab.yml`, vous trouverez une structure comme celle-ci :

```yaml
production: &base
  gitlab:
    default_theme: 2
```

Dans `gitlab.rb`, cela se traduit par :

```ruby
gitlab_rails['gitlab_default_theme'] = 2
```

Ce qui se passe ici, c'est que nous ignorons `production: &base` et joignons `gitlab:` avec `default_theme:` pour obtenir `gitlab_default_theme`. Notez que tous les paramètres de `gitlab.yml` ne peuvent pas encore être modifiés via `gitlab.rb` ; consultez le [modèle `gitlab.yml.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb). Si vous pensez qu'un attribut est manquant, veuillez créer un merge request sur le dépôt `omnibus-gitlab`.

Exécutez `sudo gitlab-ctl reconfigure` pour que les modifications apportées à `gitlab.rb` prennent effet.

Ne modifiez pas le fichier généré dans `/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`, car il est écrasé lors de la prochaine exécution de `gitlab-ctl reconfigure`.

## Ajouter un nouveau paramètre à `gitlab.yml` {#adding-a-new-setting-to-gitlabyml}

Tout d'abord, envisagez de ne pas ajouter de paramètre à `gitlab.yml`. Consultez **Paramètres** sous [GitLab-specific concerns](https://docs.gitlab.com/development/code_review/#gitlab-specific-concerns).

N'oubliez pas de mettre à jour les 5 fichiers suivants lors de l'ajout d'un nouveau paramètre :

- le fichier [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) pour exposer le paramètre à l'utilisateur final via `/etc/gitlab/gitlab.rb`.
- le fichier [`default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb) pour fournir une valeur par défaut raisonnable pour le nouveau paramètre.
- le fichier [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example) pour utiliser réellement la valeur du paramètre issue de `gitlab.rb`.
- le fichier [`gitlab.yml.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb)
- le fichier [`gitlab-rails_spec.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/spec/chef/cookbooks/gitlab/recipes/gitlab-rails_spec.rb)
