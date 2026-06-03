---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Créer un package `omnibus-gitlab` localement
---

## Préparer un environnement de build {#prepare-a-build-environment}

Les images Docker avec les outils de build nécessaires à la création des packages `omnibus-gitlab` se trouvent dans le [`GitLab Omnibus Builder`](https://gitlab.com/gitlab-org/gitlab-omnibus-builder) du projet [registre de conteneurs](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/container_registry).

1. [Installer Docker Engine](https://docs.docker.com/engine/install/).
   - Docker Engine est obligatoire, pas Docker Desktop.
   - [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/) requiert un abonnement payant pour un usage commercial, conformément au [Docker Subscription Service Agreement](https://www.docker.com/legal/docker-subscription-service-agreement/). Envisagez des alternatives.

1. Tirez (pull) l'image Docker pour le système d'exploitation pour lequel vous souhaitez créer un package. La version actuelle de l'image utilisée officiellement par `omnibus-gitlab` est indiquée dans la variable d'environnement `BUILDER_IMAGE_REVISION` de la [configuration CI](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml).

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION}
   ```

1. Clonez les sources de `omnibus-gitlab` et accédez au répertoire cloné :

   ```shell
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   cd ~/omnibus-gitlab
   ```

1. Démarrez le conteneur et accédez à son shell, tout en montant le répertoire `omnibus-gitlab` dans le conteneur :

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. Par défaut, `omnibus-gitlab` choisit des dépôts GitLab publics pour récupérer les sources des différents composants GitLab. Définissez la variable d'environnement `ALTERNATIVE_SOURCES` à `false` pour effectuer le build depuis `dev.gitlab.org`.

   ```shell
   export ALTERNATIVE_SOURCES=false
   ```

   Les informations sur les sources des composants se trouvent dans le fichier [`.custom_sources.yml`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml).

1. Par défaut, la base de code `omnibus-gitlab` est optimisée pour être utilisée dans un environnement CI. L'une de ces optimisations consiste à réutiliser les ressources Rails précompilées générées par le pipeline CI GitLab. Pour savoir comment en tirer parti dans vos builds, consultez la section [Récupérer les ressources en amont](#fetch-upstream-assets). Vous pouvez également choisir de compiler les ressources lors du build du package en définissant la variable d'environnement `COMPILE_ASSETS`.

   ```shell
   export COMPILE_ASSETS=true
   ```

1. Par défaut, la compression XZ est utilisée pour produire le package DEB final, ce qui réduit la taille du package d'environ 30 % par rapport à Gzip, avec une augmentation négligeable voire nulle du temps de build et une légère augmentation du temps d'installation (décompression). Cependant, le gestionnaire de packages du système doit également prendre en charge ce format. Si le gestionnaire de packages de votre système ne prend pas en charge les packages XZ, définissez la variable d'environnement `COMPRESS_XZ` à `false` :

   ```shell
   export COMPRESS_XZ=false
   ```

1. Installez les bibliothèques et autres dépendances :

   ```shell
   cd /omnibus-gitlab
   bundle install
   bundle binstubs --all
   ```

### Récupérer les ressources en amont {#fetch-upstream-assets}

Les pipelines des projets GitLab et GitLab-FOSS créent une image Docker avec des ressources précompilées et publient l'image dans le registre de conteneurs. Lors de la création de packages, pour gagner du temps, vous pouvez réutiliser ces images au lieu de recompiler les ressources :

1. Récupérez l'image Docker des ressources qui correspond à la référence de GitLab ou GitLab-FOSS que vous compilez. Par exemple, pour tirer (pull) l'image de ressources correspondant à la dernière référence `master`, exécutez la commande suivante :

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. Créez un conteneur à l'aide de cette image :

   ```shell
   docker create --name gitlab_asset_cache registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. Copiez le répertoire des ressources du conteneur vers l'hôte :

   ```shell
   docker cp gitlab_asset_cache:/assets ~/gitlab-assets
   ```

1. Au démarrage du conteneur de l'environnement de build, montez-y le répertoire des ressources :

   ```shell
   docker run -v ~/omnibus-gitlab:/omnibus-gitlab -v ~/gitlab-assets:/gitlab-assets -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. Au lieu de définir `COMPILE_ASSETS` à true, définissez le chemin où les ressources peuvent être trouvées :

   ```shell
   export ASSET_PATH=/gitlab-assets
   ```

## Créer le package {#build-the-package}

Après avoir préparé l'environnement de build et effectué les modifications nécessaires, vous pouvez créer des packages à l'aide des tâches Rake fournies :

1. Pour que les builds fonctionnent, le répertoire de travail Git doit être propre. Donc, committez vos modifications dans une nouvelle branche.

1. Exécutez la tâche Rake pour créer le package :

   ```shell
   bundle exec rake build:project
   ```

Les packages sont créés et mis à disposition dans le répertoire `~/omnibus-gitlab/pkg`.

### Créer un package EE {#build-an-ee-package}

Par défaut, `omnibus-gitlab` crée un package CE. Si vous souhaitez créer un package EE, définissez la variable d'environnement `ee` avant d'exécuter la tâche Rake :

```shell
export ee=true
```

### Nettoyer les fichiers créés lors du build {#clean-files-created-during-build}

Vous pouvez nettoyer tous les fichiers temporaires générés lors du processus de build en utilisant la commande `clean` de `omnibus` :

```shell
bin/omnibus clean gitlab
```

L'ajout de l'option purge `--purge` supprime **l'ensemble** des fichiers générés lors du build, y compris le répertoire d'installation du projet (`/opt/gitlab`) et le répertoire du cache de packages (`/var/cache/omnibus/pkg`) :

```shell
bin/omnibus clean --purge gitlab
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

## Obtenir de l'aide sur Omnibus {#get-help-on-omnibus}

Pour obtenir de l'aide sur l'interface de ligne de commande Omnibus, exécutez la commande `help` :

```shell
bin/omnibus help
```

<!-- vale gitlab_base.SubstitutionWarning = YES -->
