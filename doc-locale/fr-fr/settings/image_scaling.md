---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Mise à l'échelle des images"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab exécute un outil intégré de mise à l'échelle des images pour améliorer les performances de rendu du site. Il est activé par défaut.

## Configurer le metteur à l'échelle {#configure-the-scaler}

Nous nous efforçons de toujours définir des paramètres par défaut judicieux qui fonctionnent avec la grande majorité des déploiements GitLab. Cependant, nous fournissons plusieurs paramètres qui vous permettent d'ajuster la mise à l'échelle des images pour mieux correspondre au profil de performances souhaité.

### Nombre maximum de metteurs à l'échelle d'images {#maximum-number-of-image-scalers}

La remise à l'échelle des images entraîne des processus supplémentaires de courte durée qui s'exécutent sur le même nœud que Workhorse. Par défaut, nous limitons le nombre de ces processus autorisés à s'exécuter simultanément à la moitié du nombre de cœurs CPU sur cette machine ou VM, mais pas moins de deux.

Vous pouvez choisir de définir une valeur fixe à la place :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit :

   ```ruby
   gitlab_workhorse['image_scaler_max_procs'] = 10
   ```

1. Reconfigurez pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Cela signifie que si 10 images sont déjà en cours de traitement, la 11e requête ne sera pas remise à l'échelle et sera servie à la taille d'origine à la place. Définir un plafond à ce niveau est important pour garantir que le système reste disponible même sous une charge élevée.

### Taille maximale du fichier image {#maximum-image-file-size}

Par défaut, GitLab ne remet à l'échelle que les images dont la taille est d'au plus 250 ko. Cela permet d'éviter une consommation excessive de mémoire sur les nœuds Workhorse et de maintenir les latences dans des limites raisonnables. Au-delà d'une certaine taille de fichier, il est en fait globalement plus rapide de simplement servir l'image originale.

Si vous souhaitez réduire ou augmenter la taille de fichier maximale autorisée :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit :

   ```ruby
   gitlab_workhorse['image_scaler_max_filesize'] = 1024 * 1024
   ```

1. Reconfigurez pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Cela permettrait de remettre à l'échelle des images allant jusqu'à 1 Mo (l'unité est l'octet).

### Désactivation du metteur à l'échelle d'images {#disabling-the-image-scaler}

Vous pouvez décider de désactiver entièrement la mise à l'échelle des images. Cela peut être accompli en désactivant le bouton de basculement de feature flag correspondant :

```ruby
Feature.disable(:dynamic_image_resizing)
```

Référez-vous à la [documentation sur les feature flags](https://docs.gitlab.com/administration/feature_flags/) pour apprendre à utiliser les feature flags.
