---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Créer une image Docker GitLab localement
---

L'image Docker GitLab utilise le paquet Ubuntu 24.04 créé par `omnibus-gitlab`. La plupart des fichiers nécessaires à la création d'une image Docker se trouvent dans le répertoire `Docker` du dépôt `omnibus-gitlab`. Le fichier `RELEASE` ne se trouve pas dans ce répertoire, et vous devez créer ce fichier.

## Créer le fichier `RELEASE` {#create-the-release-file}

Les détails de version du paquet utilisé sont stockés dans le fichier `RELEASE`. Pour créer votre propre image Docker, créez ce fichier dans le dossier `docker/` avec un contenu similaire à ce qui suit.

```plaintext
RELEASE_PACKAGE=gitlab-ee
RELEASE_VERSION=13.2.0-ee
DOWNLOAD_URL_amd64=https://example.com/gitlab-ee_13.2.00-ee.0_amd64.deb
```

- `RELEASE_PACKAGE` indique si le paquet est un paquet CE ou EE.
- `RELEASE_VERSION` indique la version du paquet, par exemple `13.2.0-ee`.
- `DOWNLOAD_URL_amd64` indique l'URL pour amd64 à partir de laquelle ce paquet peut être téléchargé.
- `DOWNLOAD_URL_arm64` indique l'URL pour arm64 à partir de laquelle ce paquet peut être téléchargé.

> [!note]
> Nous cherchons à améliorer cette situation, et à utiliser des paquets disponibles localement [dans le ticket #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

## Créer l'image Docker {#build-the-docker-image}

Pour créer l'image Docker après avoir rempli le fichier `RELEASE` :

```shell
cd docker
docker build -t omnibus-gitlab-image:custom .
```

L'image est créée et taguée comme `omnibus-gitlab-image:custom`.
