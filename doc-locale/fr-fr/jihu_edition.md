---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: JiHu Edition
---

> [!note]
> Cette section n'est pertinente que si vous êtes un client sur le marché chinois.

GitLab a accordé une licence de sa technologie à une nouvelle société chinoise indépendante, appelée JiHu. Cette société indépendante contribuera à favoriser l'adoption de la plateforme DevOps complète GitLab en Chine et à développer la communauté GitLab et les contributions open source.

Pour plus d'informations, consultez l'[annonce sur le blog](https://about.gitlab.com/blog/2021/03/18/gitlab-licensed-technology-to-new-independent-chinese-company/) et la [FAQ](https://about.gitlab.com/pricing/faq-jihu/).

## Prérequis {#prerequisites}

Avant d'installer GitLab JiHu Edition, il est d'une importance capitale de vérifier les [prérequis](https://docs.gitlab.com/install/requirements/) système. Les prérequis système incluent des détails sur le matériel minimal, les logiciels, la base de données et les exigences supplémentaires pour prendre en charge GitLab.

Une fois que vous avez conclu un contrat avec JiHu, un représentant JiHu vous contactera pour vous fournir une licence que vous pourrez utiliser dans le cadre du processus d'installation.

## Installer ou mettre à jour un package JiHu Edition {#install-or-update-a-jihu-edition-package}

> [!note]
> Si vous effectuez une installation pour la première fois, vous devez passer la variable `EXTERNAL_URL="<GitLab URL>"` pour définir votre nom de domaine préféré. L'installation configure et démarre automatiquement GitLab à cette URL. L'activation du protocole HTTPS nécessite une [configuration supplémentaire](settings/nginx.md#enable-https) pour spécifier les certificats.

Veuillez vous référer à la page [GitLab Jihu Edition Install](https://gitlab.cn/install/) pour plus de détails sur l'installation ou la mise à jour d'un package JiHu Edition.

### Définir le mot de passe initial et appliquer la licence {#set-initial-password-and-apply-license}

Lors de la première installation de GitLab JiHu Edition, vous êtes redirigé vers un écran de réinitialisation de mot de passe. Fournissez le mot de passe du compte administrateur initial et vous serez redirigé vers l'écran de connexion. Utilisez le nom d'utilisateur `root` du compte par défaut pour vous connecter.

Pour des instructions détaillées, consultez [installation et configuration](https://docs.gitlab.com/install/package/).

De plus, vous pouvez accéder au panneau d'administration GitLab de votre serveur et [télécharger votre fichier de licence JiHu Edition](https://docs.gitlab.com/administration/license/#uploading-your-license).

## Mettre à jour GitLab Enterprise Edition vers JiHu Edition {#update-gitlab-enterprise-edition-to-jihu-edition}

Pour mettre à jour un serveur GitLab Enterprise Edition (EE) existant installé à l'aide des packages Linux vers GitLab JiHu Edition (JH), vous installez le package JiHu Edition (JH) par-dessus EE.

Les options disponibles sont :

- (Recommandé) Mise à jour depuis la même version d'EE vers JH.
- Mise à jour depuis une version inférieure d'EE vers une version supérieure de JH, à condition que ce soit un [chemin de mise à niveau](https://docs.gitlab.com/update/#upgrade-paths) pris en charge (par exemple, EE 13.5.4 vers JH 13.10.0).

Dans les étapes suivantes, nous supposons que vous mettez à jour la même version (par exemple, EE 13.10.0 vers JH 13.10.0).

Pour mettre à jour EE vers JH :

- Si vous avez installé GitLab à l'aide d'un package deb/rpm :

  1. Effectuez une [sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/).
  1. Trouvez la version de GitLab actuellement installée :

     - Pour Debian/Ubuntu :

       ```shell
       sudo apt-cache policy gitlab-ee | grep Installed
       ```

       La sortie devrait être similaire à `Installed: 13.10.0-ee.0`, donc la version installée est `13.10.0-ee.0`.

     - Pour CentOS/RHEL :

       ```shell
       sudo rpm -q gitlab-ee
       ```

       La sortie devrait être similaire à `gitlab-ee-13.10.0-ee.0.el8.x86_64`, donc la version installée est `13.10.0-ee.0`.

  1. Suivez les mêmes étapes que lors de l'[installation du package JiHu Edition](#install-or-update-a-jihu-edition-package) pour votre système d'exploitation, et assurez-vous de sélectionner la même version que celle notée à l'étape précédente. Remplacez `<url>` par l'URL de votre package.

  1. Reconfigurez GitLab :

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. Accédez au panneau d'administration GitLab de votre serveur (`/admin/license/new`) et téléchargez votre fichier de licence JiHu Edition. Si vous avez une licence EE déjà installée avant la mise à jour vers JiHu, la licence EE est automatiquement désactivée lorsque JH est installé.

  1. Vérifiez que GitLab fonctionne comme prévu, puis supprimez l'ancien dépôt Enterprise Edition :

     - Pour Debian/Ubuntu :

       ```shell
       sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ee.list
       ```

     - Pour CentOS/RHEL :

       ```shell
       sudo rm /etc/yum.repos.d/gitlab_gitlab-ee.repo
       sudo dnf config-manager --disable gitlab_gitlab-ee
       ```

- Si vous avez installé GitLab à l'aide de Docker :

  1. Suivez le [guide de mise à jour Docker](https://docs.gitlab.com/install/docker/) et remplacez `gitlab/gitlab-ee:latest` par ce qui suit :

     ```shell
     registry.gitlab.com/gitlab-jh/omnibus-gitlab/gitlab-jh:<version>
     ```

     Où `<version>` est la version de GitLab actuellement installée, que vous pouvez trouver avec :

     ```shell
     sudo docker ps | grep gitlab/gitlab-ee | awk '{print $2}'
     ```

     La sortie devrait être similaire à : `gitlab/gitlab-ee:13.10.0-ee.0`, donc dans ce cas, `<version>` est égal à `13.10.0`.

  1. Accédez au panneau d'administration GitLab de votre serveur (`/admin/license/new`) et téléchargez votre fichier de licence JiHu Edition. Si vous avez une licence EE déjà installée avant la mise à jour vers JiHu, la licence EE est automatiquement désactivée lorsque JH est installé.

C'est tout ! Vous pouvez maintenant utiliser GitLab JiHu Edition ! Pour mettre à jour vers une version plus récente, consultez [Installer ou mettre à jour un package JiHu](#install-or-update-a-jihu-edition-package).

## Revenir à GitLab Enterprise Edition {#go-back-to-gitlab-enterprise-edition}

Pour rétrograder l'installation JiHu Edition vers GitLab Enterprise Edition (EE), installez la même version du package Enterprise Edition par-dessus celui actuellement installé.

Selon la méthode d'installation préférée pour GitLab EE, soit :

- Utilisez le dépôt de packages GitLab officiel et [installez GitLab EE](https://about.gitlab.com/install/?version=ee).
- Téléchargez le package GitLab EE et [installez-le manuellement](https://docs.gitlab.com/update/package/#upgrade-with-a-downloaded-package).
