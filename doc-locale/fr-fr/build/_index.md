---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Créer des packages `omnibus-gitlab` et des images Docker localement
---

> [!note]
> Si vous êtes membre de l'équipe GitLab, vous avez accès à notre infrastructure CI qui peut être utilisée pour créer ces artefacts. Consultez la [documentation](../development/team_members.md) pour plus de détails.

## Packages `omnibus-gitlab` {#omnibus-gitlab-packages}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

`omnibus-gitlab` utilise [Omnibus](https://github.com/chef/omnibus) pour créer des packages pour les systèmes d'exploitation pris en charge. Omnibus détecte le système d'exploitation sur lequel il est utilisé et crée des packages pour ce système d'exploitation. Vous devez utiliser un conteneur Docker correspondant au système d'exploitation comme environnement pour la création de packages.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

La procédure de création d'un package personnalisé en local est décrite dans le [document dédié](build_package.md).

## Image Docker tout-en-un {#all-in-one-docker-image}

> [!note]
> Si vous souhaitez des images Docker individuelles pour chaque composant GitLab plutôt que l'image monolithique tout-en-un, consultez le [CNG](https://gitlab.com/gitlab-org/build/CNG).

L'image Docker tout-en-un de GitLab utilise le package `omnibus-gitlab` créé pour Ubuntu 24.04 en arrière-plan. Le Dockerfile est optimisé pour être utilisé dans un environnement CI, en supposant que les packages sont disponibles sur Internet.

Nous cherchons à améliorer cette situation [dans le ticket n° 5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

La procédure de création d'une image Docker tout-en-un en local est décrite dans le [document dédié](build_docker_image.md).
