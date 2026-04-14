---
stage: GitLab Delivery
group: Build
info: Pour déterminer le rédacteur technique assigné au Stage/Group associé à cette page, consultez <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Variables CI
---

Les [pipelines CI](pipelines.md) d'`omnibus-gitlab` utilisent des variables fournies par l'environnement CI pour modifier le comportement de build entre les miroirs et
garder les données sensibles hors des dépôts.

Consultez le tableau ci-dessous pour plus d'informations sur les différentes variables CI utilisées dans les pipelines.

## Variables de build

**Obligatoires** :

Ces variables sont obligatoires pour construire des packages dans le pipeline.

| Variable d'environnement    | Description |
|-------------------------|-------------|
| `AWS_SECRET_ACCESS_KEY` | Secret de compte pour lire/écrire le package de build vers un emplacement S3. |
| `AWS_ACCESS_KEY_ID`     | ID de compte pour lire/écrire le package de build vers un emplacement S3. |

**Disponibles** :

Ces variables supplémentaires sont disponibles pour remplacer ou activer différents comportements de build.

| Variable d'environnement           | Description |
| ------------------------------ | ----------- |
| `AWS_MAX_ATTEMPTS`             | Nombre maximum de fois qu'une commande S3 doit réessayer. |
| `USE_S3_CACHE`                 | Définir sur n'importe quelle valeur et Omnibus mettra en cache les sources logicielles récupérées dans un bucket s3. |
| `CACHE_AWS_ACCESS_KEY_ID`      | ID de compte pour lire/écrire depuis le bucket s3 contenant le cache de récupération logicielle s3. |
| `CACHE_AWS_SECRET_ACCESS_KEY`  | Secret de compte pour lire/écrire depuis le bucket s3 contenant le cache de récupération logicielle s3. |
| `CACHE_AWS_BUCKET`             | Nom du bucket S3 pour le cache de récupération logicielle. |
| `CACHE_AWS_S3_REGION`          | Région du bucket S3 pour écrire/lire le cache de récupération logicielle. |
| `CACHE_AWS_S3_ENDPOINT`        | Le point de terminaison HTTP ou HTTPS vers lequel envoyer les requêtes, lors de l'utilisation d'un service compatible s3. |
| `CACHE_S3_ACCELERATE`          | Définir n'importe quelle valeur active le cache de récupération logicielle s3 pour extraire en utilisant s3 accelerate. |
| `SECRET_AWS_SECRET_ACCESS_KEY` | Secret de compte pour lire la clé privée gpg de signature de package depuis un bucket s3 sécurisé. |
| `SECRET_AWS_ACCESS_KEY_ID`     | ID de compte pour lire la clé privée gpg de signature de package depuis un bucket s3 sécurisé. |
| `GPG_PASSPHRASE`               | La phrase de passe nécessaire pour utiliser la clé privée gpg de signature de package. |
| `CE_MAX_PACKAGE_SIZE_MB`       | La taille maximale de package en MB autorisée pour les packages CE avant que nous alertions l'équipe et enquêtions. |
| `EE_MAX_PACKAGE_SIZE_MB`       | La taille maximale de package en MB autorisée pour les packages EE avant que nous alertions l'équipe et enquêtions. |
| `DEV_GITLAB_SSH_KEY`           | Clé privée SSH pour un compte capable de lire les dépôts depuis `dev.gitlab.org`. Utilisée pour la récupération Git SSH. |
| `BUILDER_IMAGE_REGISTRY`       | Registre depuis lequel extraire les images de tâche CI. |
| `BUILD_LOG_LEVEL`              | Niveau de log de build Omnibus. |
| `ALTERNATIVE_SOURCES`          | Basculer vers les sources personnalisées listées dans `https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml` Par défaut à `true`. |
| `OMNIBUS_GEM_SOURCE`           | URI distant non par défaut depuis lequel cloner la gem omnibus. |
| `QA_BUILD_TARGET`              | Construire l'image QA spécifiée. Voir cette [MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91250) pour les détails. Par défaut à `qa`. |
| `GITLAB_ASSETS_TAG`            | Tag de l'image d'assets construite par la tâche `build-assets-image` dans les pipelines `gitlab-org/gitlab`. Par défaut à `$GITLAB_REF_SLUG` ou la version `gitlab-rails`. |
| `BUILD_ON_ALL_OS`              | Construire toutes les images OS sans utiliser de déclencheur manuel si défini à `true`. |

## Variables de test

| Variable d'environnement                         | Description |
|----------------------------------------------|-------------|
| `RAT_REFERENCE_ARCHITECTURE`                 | Modèle d'architecture de référence utilisé dans le pipeline déclenché par la tâche RAT. |
| `RAT_FIPS_REFERENCE_ARCHITECTURE`            | Modèle d'architecture de référence utilisé dans le pipeline déclenché par la tâche RAT:FIPS. |
| `RAT_PACKAGE_URL`                            | URL pour récupérer le package régulier - pour le pipeline RAT déclenché par la tâche RAT. |
| `RAT_FIPS_PACKAGE_URL`                       | URL pour récupérer le package FIPS - pour le pipeline RAT déclenché par la tâche RAT. |
| `RAT_TRIGGER_TOKEN`                          | Token de déclenchement pour le pipeline RAT. |
| `RAT_PROJECT_ACCESS_TOKEN`                   | Token d'accès au projet pour déclencher un pipeline RAT. |
| `OMNIBUS_GITLAB_MIRROR_PROJECT_ACCESS_TOKEN` | Token d'accès au projet pour construire un package de test. |
| `CI_SLACK_WEBHOOK_URL`                       | URL de webhook pour les notifications d'échec Slack. |
| `DANGER_GITLAB_API_TOKEN`                    | Token d'API GitLab pour que dangerbot poste des commentaires sur les MR. |
| `DOCS_API_TOKEN`                             | Token utilisé par CI pour déclencher un build review-app du site de documentation. |
| `MANUAL_QA_TEST`                             | Variable utilisée pour décider si la tâche `qa-subset-test` doit être jouée automatiquement ou non. |

## Variables de release

**Obligatoires** :

Ces variables sont obligatoires pour publier les packages construits par le pipeline.

| Variable d'environnement            | Description |
|---------------------------------|-------------|
| `STAGING_REPO`                  | Dépôt sur `packages.gitlab.com` où les releases sont téléchargées avant la release finale. |
| `STAGING_REPO_TOKEN`            | Token maître PackageCloud qui est utilisé par CI pour télécharger le script d'installation. Les valeurs proviennent de la [page `Tokens`](https://packages.gitlab.com/gitlab/pre-release/tokens) du dépôt de packages `gitlab/pre-release`. Voir [documentation ici](https://packagecloud.io/docs#master_tokens). |
| `PACKAGECLOUD_USER`             | Nom d'utilisateur Packagecloud pour pousser les packages vers `packages.gitlab.com`. |
| `PACKAGECLOUD_TOKEN`            | Token d'accès API pour pousser les packages vers `packages.gitlab.com`. La valeur doit provenir de la page [token API](https://packages.gitlab.com/api_token). Cette valeur est utilisée par la CLI `packagecloud` pour exécuter `packagecloud push`. Voir [documentation ici](https://www.rubydoc.info/gems/package_cloud/#environment-variables). |
| `LICENSE_S3_BUCKET`             | Bucket pour stocker les informations de licence de release publiées sur la page publique à `https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html`. |
| `LICENSE_AWS_SECRET_ACCESS_KEY` | Secret de compte pour lire/écrire depuis le bucket S3 contenant les informations de licence. |
| `LICENSE_AWS_ACCESS_KEY_ID`     | ID de compte pour lire/écrire depuis le bucket S3 contenant les informations de licence. |
| `GCP_SERVICE_ACCOUNT`           | Utilisé pour lire/écrire les métriques dans Google Object Storage. |
| `DOCKERHUB_USERNAME`            | Nom d'utilisateur utilisé lors de la poussée de l'image Omnibus GitLab vers Docker Hub. |
| `DOCKERHUB_PASSWORD`            | Mot de passe utilisé lors de la poussée de l'image Omnibus GitLab vers Docker Hub. |
| `AWS_ULTIMATE_LICENSE_FILE`     | Licence GitLab Ultimate pour utiliser les AMI AWS Ultimate. |
| `AWS_PREMIUM_LICENSE_FILE`      | Licence GitLab Premium pour utiliser les AMI AWS Ultimate. |
| `AWS_AMI_SECRET_ACCESS_KEY`     | Secret de compte pour l'accès en lecture/écriture pour publier les AMI AWS. |
| `AWS_AMI_ACCESS_KEY_ID`         | ID de compte pour l'accès en lecture/écriture pour publier les AMI AWS. |
| `AWS_MARKETPLACE_ARN`           | ARN AWS pour permettre à AWS Marketplace d'accéder à nos AMI officielles. |
| `PACKAGE_PROMOTION_RUNNER_TAG`  | Tag associé aux runners partagés utilisés pour exécuter les tâches de promotion de packages. |

**Disponibles** :

Ces variables supplémentaires sont disponibles pour remplacer ou activer différents comportements de build.

| Variable d'environnement             | Description |
|----------------------------------|-------------|
| `PATCH_DEPLOY_ENVIRONMENT`       | Nom de déploiement utilisé pour le déclencheur du [déployeur `gitlab.com`](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) si la ref actuelle est un tag de candidat à la release. |
| `AUTO_DEPLOY_ENVIRONMENT`        | Nom de déploiement utilisé pour le déclencheur du [déployeur `gitlab.com`](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) si la ref actuelle est un tag de déploiement automatique. |
| `DEPLOYER_TRIGGER_PROJECT`       | ID de projet GitLab pour le dépôt utilisé pour le [déployeur `gitlab.com`](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md). |
| `DEPLOYER_TRIGGER_TOKEN`         | Token de déclenchement pour les différents environnements du [déployeur `gitlab.com`](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md). |
| `RELEASE_BUCKET`                 | Bucket S3 où les packages de release sont poussés. |
| `BUILDS_BUCKET`                  | Bucket S3 où les packages de branche réguliers sont poussés. |
| `RELEASE_BUCKET_REGION`          | Région du bucket S3. |
| `RELEASE_BUCKET_S3_ENDPOINT`     | Spécifier le point de terminaison S3. Particulièrement utile lorsqu'un service de stockage compatible S3 est adopté. |
| `GITLAB_BUNDLE_GEMFILE`          | Définir le chemin Gemfile requis par le bundle `gitlab-rails`. Par défaut `Gemfile`. |
| `GITLAB_COM_PKGS_RELEASE_BUCKET` | Bucket GCS où les packages de release sont poussés. |
| `GITLAB_COM_PKGS_BUILDS_BUCKET`  | Bucket GCS où les packages de branche réguliers sont poussés. |
| `GITLAB_COM_PKGS_SA_FILE`        | Clé de compte de service utilisée pour pousser les packages de release pour les déploiements SaaS, elle doit avoir un accès en écriture au bucket pkgs. |
| `GITLAB_NAMESPACE`               | Utilisé pour remplacer les URL d'image dans l'instance Dev, puisque le nom de niveau supérieur là-bas diverge de `gitlab-org` vers `gitlab`. |
| `PACKAGECLOUD_ENABLED`           | Définir à `"true"` pour activer le téléchargement de packages vers PackageCloud (`packages.gitlab.com`). Par défaut à `"false"`. Voir [ticket de décommissionnement](https://gitlab.com/gitlab-org/build/team-tasks/-/work_items/177). |

## Variables inconnues/obsolètes

| Variable d'environnement           | Description |
|--------------------------------|-------------|
| `VERSION_TOKEN`                |             |
| `TAKEOFF_TRIGGER_TOKEN`        |             |
| `TAKEOFF_TRIGGER_PROJECT`      |             |
| `RELEASE_TRIGGER_TOKEN`        |             |
| `GITLAB_DEV`                   |             |
| `FOG_REGION`                   |             |
| `FOG_PROVIDER`                 |             |
| `FOG_DIRECTORY`                |             |
| `AWS_RELEASE_TRIGGER_TOKEN`    | Utilisé pour les releases antérieures à 13.10. |
| `ASSETS_AWS_SECRET_ACCESS_KEY` |             |
| `ASSETS_AWS_ACCESS_KEY_ID`     |             |
| `AMI_LICENSE_FILE`             |             |

## Variables DockerHub

Par défaut, CI utilise des images depuis DockerHub. Les runners par défaut/partagés
et les runners de distribution utilisent un miroir DockerHub pour éviter d'atteindre
les limites de taux.

Si vous utilisez des runners personnalisés, qui n'utilisent pas de mise en cache ou de mise en miroir, vous
devriez activer le proxy de dépendance en définissant le `DOCKERHUB_PREFIX`
sur votre proxy, par exemple
`DOCKERHUB_PREFIX: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}`, et
`DEPENDENCY_PROXY_LOGIN="true"`.

Le contexte de build de conteneur utilise par défaut le miroir DockerHub gcr. Ce
comportement peut être modifié en remplaçant les variables `DOCKER_OPTIONS` ou `DOCKER_MIRROR`.
