---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Processus de release d'Omnibus GitLab
---

Notre objectif principal est de clarifier quelle version de GitLab se trouve dans un
package Linux.

## Comment le package Linux officiel est-il construit

La construction du package officiel est entièrement automatisée par GitLab Inc.

Nous pouvons différencier deux types de construction :

- Packages pour release vers <https://packages.gitlab.com>.
- Packages de test construits à partir de branches disponibles dans des buckets S3.

Les deux types sont construits sur la même infrastructure.

## Infrastructure

Chaque package est construit sur la plateforme pour laquelle il est destiné (les packages CentOS 6 sont
construits sur des serveurs CentOS6, les packages Debian 8 sur des serveurs Debian 8 et ainsi de suite).
Le nombre de serveurs de construction varie mais il y a toujours au moins un serveur de
construction par plateforme.

Le projet `omnibus-gitlab` utilise entièrement GitLab CI/CD. Cela signifie que chaque push
vers le dépôt `omnibus-gitlab` déclenche une construction dans GitLab CI/CD qui
crée ensuite un package.

Étant donné que nous déployons GitLab.com en utilisant des packages Linux, nous avons besoin d'un
remote séparé pour construire les packages en cas de problème avec GitLab.com ou en raison
d'une release de sécurité d'un package.

Ce remote est situé sur `https://dev.gitlab.org`. La seule différence entre le
projet `omnibus-gitlab` sur `https://dev.gitlab.org` et les autres remotes publics est que le
projet a GitLab CI actif et a des runners spécifiques assignés au projet
qui s'exécutent sur les serveurs de construction. C'est également le cas pour tous les composants GitLab,
par exemple GitLab Shell est exactement le même sur `https://dev.gitlab.org` qu'il l'est sur GitLab.com.

Tous les serveurs de construction exécutent [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) et tous les runners utilisent une clé de déploiement
pour se connecter aux projets sur `https://dev.gitlab.org`. Les serveurs de construction ont également
accès au dépôt de packages officiel sur <https://packages.gitlab.com> et à un bucket
Amazon S3 spécial qui stocke les packages de test.

## Processus de construction

GitLab Inc utilise le [projet release-tools](https://gitlab.com/gitlab-org/release-tools/tree/master) pour automatiser les tâches de release
pour chaque release. Lorsque le gestionnaire de release démarre le processus de release, plusieurs
choses importantes seront effectuées :

1. Tous les remotes du projet seront synchronisés.
1. Les versions des composants seront lues depuis le dépôt GitLab CE/EE
   (par exemple, `VERSION`, `GITLAB_SHELL_VERSION`) et écrites dans le dépôt `omnibus-gitlab`.
1. Un tag Git spécifique sera créé et synchronisé vers les dépôts `omnibus-gitlab`.

Lorsque le dépôt `omnibus-gitlab` sur `https://dev.gitlab.org` est mis à jour, la construction GitLab CI
est déclenchée.

Les étapes spécifiques peuvent être vues dans le fichier `.gitlab-ci.yml` du dépôt `omnibus-gitlab`.
Les constructions sont exécutées sur toutes les plateformes en même temps.

Pendant la construction, `omnibus-gitlab` récupère les bibliothèques externes depuis leurs emplacements
sources et les composants GitLab comme GitLab, GitLab Shell, GitLab Workhorse, et
ainsi de suite sont récupérés depuis `https://dev.gitlab.org`.

Une fois la construction terminée et les packages .deb ou .rpm construits, selon
le type de construction, le package sera poussé vers <https://packages.gitlab.com> ou vers un bucket
S3 temporaire (les fichiers de plus de 30 jours sont purgés).

## Spécifier manuellement les versions des composants

### Sur votre machine de développement

1. Choisissez un tag de GitLab à packager (par exemple `v6.6.0`).
1. Créez une branche de release dans votre dépôt `omnibus-gitlab` (par exemple, `6-6-stable`).
1. Si la branche de release existe déjà, par exemple parce que vous effectuez une
   release de correctif, assurez-vous de récupérer les dernières modifications sur votre machine locale :

   ```shell
   git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # branche de release existante
   ```

1. Utilisez `support/set-revisions` pour définir les révisions des fichiers dans
   `config/software/`. Il prendra les noms de tags et recherchera les SHA1 Git, et définira
   les sources de téléchargement sur `https://dev.gitlab.org`. Utilisez `set-revisions --ee` pour une release EE :

   ```shell
   # utilisation : set-revisions [--ee] GITLAB_RAILS_REF GITLAB_SHELL_REF GITALY_REF GITLAB_ELASTICSEARCH_INDEXER_REF

   # Pour GitLab CE :
   support/set-revisions v1.2.3 v1.2.3 1.2.3 1.2.3 1.2.3

   # Pour GitLab EE :
   support/set-revisions --ee v1.2.3-ee v1.2.3 1.2.3 1.2.3 1.2.3
   ```

1. Commitez la nouvelle version dans la branche de release :

   ```shell
   git add VERSION GITLAB_SHELL_VERSION GITALY_SERVER_VERSION
   git commit
   ```

1. Créez un tag annoté dans `omnibus-gitlab` correspondant au tag GitLab.
   Le tag `omnibus-gitlab` ressemble à : `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`, où
   `MAJOR.MINOR.PATCH` est la version GitLab, `OTHER` peut être quelque chose comme `ce`,
   `ee` ou `rc1` (ou `rc1.ee`), et `OMNIBUS_RELEASE` est un nombre (commençant à 0) :

   ```shell
   git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
   ```

   > [!warning]
   > N'utilisez PAS de trait d'union `-` n'importe où dans le tag `omnibus-gitlab`.

   Exemples de conversion d'un tag upstream vers une séquence de tags `omnibus-gitlab` :

   | tag upstream     | séquence de tags `omnibus-gitlab`           |
   | ------------     | --------------------                        |
   | `v7.10.4`        | `7.10.4+ce.0`, `7.10.4+ce.1`, `...`         |
   | `v7.10.4-ee`     | `7.10.4+ee.0`, `7.10.4+ee.1`, `...`         |
   | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`, `7.11.0+rc1.ee.1`, `...` |

1. Poussez la branche et le tag vers `https://gitlab.com` et `https://dev.gitlab.org` :

   ```shell
   git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   ```

   Pousser un tag annoté vers `https://dev.gitlab.org` déclenche une release de package.

### Publication des packages

Vous pouvez suivre le progrès de la construction des packages sur `https://dev.gitlab.org/gitlab/omnibus-gitlab/builds`.
Ils sont poussés vers nos [dépôts `packages.gitlab.com`](https://packages.gitlab.com/gitlab/) automatiquement après
des constructions réussies.

### Mise à jour des images cloud

Le processus de release des images cloud est documenté ici : <https://handbook.gitlab.com/handbook/alliances/cloud-images/>.

De nouvelles images sont publiées lorsque :

1. Il y a une nouvelle release mensuelle de GitLab.
1. Une vulnérabilité de sécurité a été corrigée dans une release de correctif.
1. Il y a un correctif qui résout un problème critique impactant l'image.

Les nouvelles images doivent être publiées dans les 3 jours ouvrables suivant la release du package.

Documentation de release spécifique aux images :

- (**Déprécié**) [OpenShift](https://docs.gitlab.com/charts/development/release/).
