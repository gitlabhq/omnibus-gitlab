---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Processus de release Omnibus GitLab
---

Notre principal objectif est de clarifier quelle version de GitLab se trouve dans un package Linux.

## Comment est construit le package Linux officiel {#how-is-the-official-linux-package-built}

La construction du package officiel est entièrement automatisée par GitLab Inc.

Nous pouvons différencier deux types de build :

- Packages destinés à la release sur <https://packages.gitlab.com>.
- Packages de test construits à partir de branches disponibles dans des buckets S3.

Les deux types sont construits sur la même infrastructure.

## Infrastructure {#infrastructure}

Chaque package est construit sur la plateforme pour laquelle il est destiné (les packages CentOS 6 sont construits sur des serveurs CentOS 6, les packages Debian 8 sur des serveurs Debian 8, et ainsi de suite). Le nombre de serveurs de build varie, mais il y a toujours au moins un serveur de build par plateforme.

Le projet `omnibus-gitlab` utilise pleinement GitLab CI/CD. Cela signifie que chaque push vers le dépôt `omnibus-gitlab` déclenche un build dans GitLab CI/CD, qui crée ensuite un package.

Étant donné que nous déployons GitLab.com en utilisant des packages Linux, nous avons besoin d'un remote distinct pour construire les packages en cas de problème avec GitLab.com ou en raison d'une release de sécurité d'un package.

Ce remote est situé sur `https://dev.gitlab.org`. La seule différence entre le projet `omnibus-gitlab` sur `https://dev.gitlab.org` et les autres remotes publics est que le projet dispose de GitLab CI actif et que des runners spécifiques sont assignés au projet, lesquels s'exécutent sur les serveurs de build. C'est également le cas pour tous les composants GitLab, par exemple, GitLab Shell est exactement le même sur `https://dev.gitlab.org` que sur GitLab.com.

Tous les serveurs de build exécutent [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) et tous les runners utilisent une clé de déploiement pour se connecter aux projets sur `https://dev.gitlab.org`. Les serveurs de build ont également accès au dépôt de packages officiel sur <https://packages.gitlab.com> et à un bucket Amazon S3 spécial qui stocke les packages de test.

## Processus de build {#build-process}

GitLab Inc utilise le [projet release-tools](https://gitlab.com/gitlab-org/release-tools/tree/master) pour automatiser les tâches de release pour chaque release. Lorsque le gestionnaire de release démarre le processus de release, quelques opérations importantes seront effectuées :

1. Tous les remotes du projet seront synchronisés.
1. Les versions des composants seront lues depuis le dépôt GitLab CE/EE (par exemple, `VERSION`, `GITLAB_SHELL_VERSION`) et écrites dans le dépôt `omnibus-gitlab`.
1. Un tag Git spécifique sera créé et synchronisé avec les dépôts `omnibus-gitlab`.

Lorsque le dépôt `omnibus-gitlab` sur `https://dev.gitlab.org` est mis à jour, le build GitLab CI est déclenché.

Les étapes spécifiques peuvent être consultées dans le fichier `.gitlab-ci.yml` du dépôt `omnibus-gitlab`. Les builds sont exécutés sur toutes les plateformes en même temps.

Pendant le build, `omnibus-gitlab` récupère les bibliothèques externes depuis leurs emplacements sources, et les composants GitLab tels que GitLab, GitLab Shell, GitLab Workhorse, etc. sont récupérés depuis `https://dev.gitlab.org`.

Une fois le build terminé et les packages .deb ou .rpm construits, selon le type de build, le package sera envoyé vers <https://packages.gitlab.com> ou vers un bucket S3 temporaire (les fichiers de plus de 30 jours sont purgés).

## Spécification manuelle des versions de composants {#specifying-component-versions-manually}

### Sur votre machine de développement {#on-your-development-machine}

1. Choisissez un tag de GitLab à packager (par exemple `v6.6.0`).
1. Créez une branche de release dans votre dépôt `omnibus-gitlab` (par exemple, `6-6-stable`).
1. Si la branche de release existe déjà, par exemple parce que vous effectuez une release de correctif, assurez-vous de récupérer les dernières modifications sur votre machine locale :

   ```shell
   git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # existing release branch
   ```

1. Utilisez `support/set-revisions` pour définir les révisions des fichiers dans `config/software/`. Il prendra les noms de tags, recherchera les SHA1 Git correspondants et définira les sources de téléchargement sur `https://dev.gitlab.org`. Utilisez `set-revisions --ee` pour une release EE :

   ```shell
   # usage: set-revisions [--ee] GITLAB_RAILS_REF GITLAB_SHELL_REF GITALY_REF GITLAB_ELASTICSEARCH_INDEXER_REF

   # For GitLab CE:
   support/set-revisions v1.2.3 v1.2.3 1.2.3 1.2.3 1.2.3

   # For GitLab EE:
   support/set-revisions --ee v1.2.3-ee v1.2.3 1.2.3 1.2.3 1.2.3
   ```

1. Commitez la nouvelle version dans la branche de release :

   ```shell
   git add VERSION GITLAB_SHELL_VERSION GITALY_SERVER_VERSION
   git commit
   ```

1. Créez une étiquette annotée dans `omnibus-gitlab` correspondant au tag GitLab. Le tag `omnibus-gitlab` ressemble à : `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`, où `MAJOR.MINOR.PATCH` est la version de GitLab, `OTHER` peut être quelque chose comme `ce`, `ee` ou `rc1` (ou `rc1.ee`), et `OMNIBUS_RELEASE` est un nombre (commençant à 0) :

   ```shell
   git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
   ```

   > [!warning]
   > N'utilisez PAS de trait d'union `-` dans le tag `omnibus-gitlab`.

   Exemples de conversion d'un tag upstream en séquence de tags `omnibus-gitlab` :

   | tag upstream     | séquence de tags `omnibus-gitlab`               |
   | ------------     | --------------------                        |
   | `v7.10.4`        | `7.10.4+ce.0`, `7.10.4+ce.1`, `...`         |
   | `v7.10.4-ee`     | `7.10.4+ee.0`, `7.10.4+ee.1`, `...`         |
   | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`, `7.11.0+rc1.ee.1`, `...` |

1. Poussez la branche et le tag vers `https://gitlab.com` et `https://dev.gitlab.org` :

   ```shell
   git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   ```

   Le push d'une étiquette annotée vers `https://dev.gitlab.org` déclenche une release de package.

### Publication des packages {#publishing-the-packages}

Vous pouvez suivre la progression de la construction des packages sur `https://dev.gitlab.org/gitlab/omnibus-gitlab/builds`. Ils sont poussés automatiquement vers nos [dépôts `packages.gitlab.com`](https://packages.gitlab.com/gitlab/) après des builds réussis.

### Mise à jour des images cloud {#updating-cloud-images}

Le processus de release des images cloud est documenté ici : <https://handbook.gitlab.com/handbook/alliances/cloud-images/>.

De nouvelles images sont publiées dans les cas suivants :

1. Il y a une nouvelle release mensuelle de GitLab.
1. Une vulnérabilité de sécurité a été corrigée dans une release de correctif.
1. Il existe un correctif qui résout un problème critique affectant l'image.

Les nouvelles images doivent être publiées dans les 3 jours ouvrables suivant la release du package.

Documentation de release spécifique aux images :

- (**Déprécié**) [OpenShift](https://docs.gitlab.com/charts/development/release/).
