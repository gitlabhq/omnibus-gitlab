---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exécution sur un Raspberry Pi
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour exécuter GitLab Community Edition sur un Raspberry Pi, vous avez besoin du dernier Pi 4 avec au moins 4 Go de RAM pour de meilleurs résultats. Vous pourriez être en mesure d'exécuter GitLab avec des ressources moindres, comme un Pi 3 ou plus récent, mais cela n'est pas recommandé. Nous ne fournissons pas de paquets pour les anciens Raspberry Pi, car leur CPU et leur RAM sont insuffisants.

Pour vous assurer que l'appareil dispose de suffisamment de mémoire, augmentez l'espace d'échange à 4 Go.

## Installer GitLab {#install-gitlab}

À partir de GitLab version 18.0, nous ne fournissons plus de packages 32 bits pour Raspberry Pi.

Vous devez utiliser [Raspberry Pi OS 64 bits](https://www.raspberrypi.com/software/operating-systems/) et [installer GitLab en utilisant les packages Debian `arm64`](https://docs.gitlab.com/install/package/debian/).

Pour obtenir des informations sur la sauvegarde des données sur un OS 32 bits et leur restauration sur un OS 64 bits, consultez [Mise à niveau des systèmes d'exploitation pour PostgreSQL](https://docs.gitlab.com/administration/postgresql/upgrading_os/).

## Réduire les processus en cours d'exécution {#reduce-running-processes}

Si vous constatez que votre Pi a du mal à exécuter GitLab, vous pouvez réduire certains processus en cours d'exécution.

Pour plus d'informations, consultez comment exécuter GitLab dans un [environnement à mémoire limitée](memory_constrained_envs.md).

## Recommandations supplémentaires {#additional-recommendations}

Vous pouvez améliorer les performances de GitLab avec quelques paramètres.

### Utiliser un disque dur approprié {#use-a-proper-hard-drive}

GitLab offrira de meilleures performances si vous montez `/var/opt/gitlab` et le fichier d'échange depuis un disque dur plutôt que depuis la carte SD. Vous pouvez connecter un disque dur externe au Pi via l'interface USB.

### Utiliser des services externes {#use-external-services}

Vous pouvez améliorer les performances de GitLab sur le Pi en connectant GitLab à des instances externes de [base de données](database.md#using-a-non-packaged-postgresql-database-management-server) et de [Redis](https://docs.gitlab.com/administration/redis/standalone/).
