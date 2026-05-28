---
stage: Data Stores
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exécuter GitLab dans un environnement à mémoire limitée
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab nécessite une quantité importante de mémoire lorsqu'il est exécuté avec toutes les fonctionnalités activées. Il existe des cas d'utilisation, comme l'exécution de GitLab sur des installations plus petites, où toutes les fonctionnalités ne sont pas nécessaires. Voici quelques exemples :

- Utilisation de GitLab pour un usage personnel ou pour de très petites équipes.
- Utilisation d'une petite instance chez un fournisseur cloud pour réduire les coûts.
- Utilisation d'appareils à ressources limitées comme le Raspberry PI.

Avec quelques ajustements, GitLab peut fonctionner confortablement sur des spécifications bien inférieures à celles décrites dans les [exigences minimales](https://docs.gitlab.com/install/requirements/) ou les [architectures de référence](https://docs.gitlab.com/administration/reference_architectures/).

Bien que la plupart des composants de GitLab devraient être fonctionnels avec ces paramètres en place, vous pourriez constater une dégradation inattendue des fonctionnalités du produit et des performances.

> [!note]
> Les sections suivantes décrivent comment exécuter GitLab pour jusqu'à 5 développeurs avec des dépôts Git individuels ne dépassant pas 100 Mo.

## Exigences minimales pour les environnements contraints {#minimum-requirements-for-constrained-environments}

Les spécifications minimales attendues pour exécuter GitLab sont les suivantes :

- Système basé sur Linux (idéalement basé sur Debian ou RedHat)
- 4 cœurs CPU ARM7/ARM64 ou 1 cœur CPU d'architecture AMD64
- Minimum 2 Go de RAM + 1 Go de SWAP, idéalement 2,5 Go de RAM + 1 Go de swap
- 20 Go de stockage disponible
- Un stockage avec de bonnes performances d'I/O aléatoires, par ordre de préférence :
  - [SSD](https://en.wikipedia.org/wiki/Solid-state_drive)
  - [eMMC](https://magazine.odroid.com/article/emmc-memory-modules-a-simple-guide/)
  - [HDD](https://en.wikipedia.org/wiki/Hard_disk_drive)
  - [Carte SD haute performance de type A1](https://www.sdcard.org/developers/sd-standard-overview/application-performance-class/)

Dans la liste ci-dessus, les performances monocœur du CPU et les performances d'I/O aléatoires du stockage ont le plus grand impact. Le stockage est particulièrement important car dans un environnement contraint, on s'attend à ce qu'une certaine quantité de swap mémoire se produise, ce qui augmente la pression sur le disque utilisé. Un problème courant pour les performances limitées des petites plateformes est un stockage sur disque très lent, ce qui entraîne un goulot d'étranglement à l'échelle du système.

Avec ces paramètres minimaux, le système devrait utiliser le swap lors d'une utilisation normale. Étant donné que tous les composants ne sont pas utilisés en même temps, cela devrait offrir des performances acceptables.

## Valider les performances de votre système {#validate-the-performance-of-your-system}

Il existe un certain nombre d'outils disponibles qui vous permettent de valider les performances de votre système basé sur Linux. L'un des projets pouvant aider à vérifier les performances de votre système est [sbc-bench](https://github.com/ThomasKaiser/sbc-bench). Il décrit toutes les nuances des tests système et l'impact des différents comportements sur les performances de votre système, ce qui est particulièrement important lors de l'exécution de GitLab dans un système embarqué. Il peut être utilisé pour valider si les performances de votre système sont suffisantes pour exécuter GitLab dans un environnement contraint.

Ces systèmes offrent des performances adéquates pour exécuter de petites installations de GitLab :

- [Raspberry PI 4 2 Go](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/).
- [DigitalOcean Basic 2 Go avec SSD](https://www.digitalocean.com/pricing).
- [Scaleway DEV1-S 2 Go/20 Go](https://www.scaleway.com/en/pricing/).
- [GCS e2-small](https://cloud.google.com/compute/docs/machine-resource).

## Configurer le Swap {#configure-swap}

Avant d'installer GitLab, vous devez configurer le swap. Le swap est un espace dédié sur le disque utilisé lorsque la RAM physique est pleine. Lorsqu'un système Linux manque de RAM, les pages inactives sont déplacées de la RAM vers l'espace swap.

L'utilisation du swap est souvent considérée comme un problème car elle peut augmenter la latence. Cependant, en raison du fonctionnement de GitLab, une grande partie de la mémoire allouée n'est pas fréquemment sollicitée. L'utilisation du swap permet à l'application de fonctionner normalement et de n'utiliser le swap que de temps à autre.

Une règle générale est de configurer le swap à environ 50 % de la mémoire disponible. Pour les environnements à mémoire limitée, il est recommandé de configurer au moins 1 Go de swap pour le système. Il existe un certain nombre de guides pour vous expliquer comment procéder :

- [How to Add Swap Space on Ubuntu 20.04](https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-20-04/)
- [How to Add Swap Space on CentOS 7](https://linuxize.com/post/how-to-add-swap-space-on-centos-7/)

Une fois configuré, vous devez vérifier que le swap est correctement activé :

```shell
free -h
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       115Mi       1.4Gi       0.0Ki       475Mi       1.6Gi
Swap:         1.0Gi          0B       1.0Gi
```

Vous pouvez également configurer la fréquence à laquelle le système utilisera l'espace swap en ajustant `/proc/sys/vm/swappiness`. La valeur de swappiness est comprise entre `0` et `100`. La valeur par défaut est `60`. Une valeur plus faible réduit la préférence de Linux à libérer les pages mémoire anonymes et à les écrire dans le swap, mais augmente sa préférence à faire de même avec les pages sauvegardées sur des fichiers :

1. Configurez-le dans la session en cours :

   ```shell
   sudo sysctl vm.swappiness=10
   ```

1. Modifiez `/etc/sysctl.conf` pour le rendre permanent :

   ```shell
   vm.swappiness=10
   ```

## Installer GitLab {#install-gitlab}

Dans un environnement à mémoire limitée, vous devez choisir la distribution GitLab qui vous convient.

[GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/) offre nettement plus de fonctionnalités que [GitLab Community Edition (CE)](https://about.gitlab.com/install/?version=ce), mais toutes ces fonctionnalités supplémentaires augmentent les besoins en calcul et en mémoire.

Lorsque la consommation de mémoire est la préoccupation principale, installez GitLab CE. Vous pouvez toujours [passer à GitLab EE](https://docs.gitlab.com/update/convert_to_ee/package/) ultérieurement.

## Optimiser Puma {#optimize-puma}

Par défaut, GitLab s'exécute avec une configuration conçue pour gérer de nombreuses connexions simultanées.

Pour les petites installations qui ne nécessitent pas un débit élevé, [désactivez le mode Clustered de Puma](https://docs.gitlab.com/administration/operations/puma/#disable-puma-clustered-mode-in-memory-constrained-environments). Cette configuration n'exécute qu'un seul processus Puma pour servir l'application.

Dans `/etc/gitlab/gitlab.rb` :

```ruby
puma['worker_processes'] = 0
```

Nous avons observé une réduction de l'utilisation de la mémoire de 100 à 400 Mo grâce à cette optimisation.

## Optimiser Sidekiq {#optimize-sidekiq}

Sidekiq est un démon de traitement en arrière-plan. Lorsqu'il est configuré avec GitLab par défaut, il s'exécute avec un mode de concurrence de `20`. Cela a un impact sur la quantité de mémoire qu'il peut allouer à un moment donné. Il est recommandé de le configurer pour utiliser une valeur nettement plus faible de `5` ou `10` (recommandé).

Dans `/etc/gitlab/gitlab.rb` :

```ruby
sidekiq['concurrency'] = 10
```

## Optimiser Gitaly {#optimize-gitaly}

Gitaly est un service de stockage qui permet un accès efficace aux dépôts basés sur Git. Il est recommandé de configurer une concurrence maximale et des limites de mémoire appliquées par Gitaly.

Dans `/etc/gitlab/gitlab.rb` :

```ruby
gitaly['configuration'] = {
    concurrency: [
      {
        'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
        'max_per_repo' => 3,
      }, {
        'rpc' => "/gitaly.SSHService/SSHUploadPack",
        'max_per_repo' => 3,
      },
    ],
    cgroups: {
        repositories: {
            count: 2,
        },
        mountpoint: '/sys/fs/cgroup',
        hierarchy_root: 'gitaly',
        memory_bytes: 500000,
        cpu_shares: 512,
    },
}

gitaly['env'] = {
  'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
}
```

## Désactiver la surveillance {#disable-monitoring}

GitLab active tous les services par défaut pour fournir une solution DevOps complète sans configuration supplémentaire. Certains des services par défaut, comme la surveillance, ne sont pas essentiels au fonctionnement de GitLab et peuvent être désactivés pour économiser de la mémoire.

Dans `/etc/gitlab/gitlab.rb` :

```ruby
alertmanager['enable'] = false
gitlab_exporter['enable'] = false
gitlab_kas['enable'] = false
node_exporter['enable'] = false
postgres_exporter['enable'] = false
prometheus_monitoring['enable'] = false
prometheus['enable'] = false
puma['exporter_enabled'] = false
redis_exporter['enable'] = false
sidekiq['metrics_enabled'] = false
```

Nous avons observé une réduction de l'utilisation de la mémoire de 300 Mo en configurant GitLab de cette façon.

## Configurer la gestion de la mémoire par GitLab {#configure-how-gitlab-handles-memory}

GitLab est composé de nombreux composants (écrits en Ruby et Go), GitLab Rails étant le plus important et consommant le plus de mémoire.

GitLab Rails utilise [jemalloc](https://github.com/jemalloc/jemalloc) comme allocateur de mémoire. [jemalloc](https://github.com/jemalloc/jemalloc) préalloue la mémoire en blocs plus importants qui sont également conservés plus longtemps afin d'améliorer les performances. Au prix d'une légère perte de performances, vous pouvez configurer GitLab pour libérer la mémoire immédiatement après qu'elle n'est plus nécessaire au lieu de la conserver pendant de plus longues périodes.

Dans `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_rails['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}

gitaly['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}
```

Nous avons observé une utilisation de la mémoire bien plus stable lors de l'exécution de l'application.

## Désactiver la surveillance supplémentaire intégrée à l'application {#disable-additional-in-application-monitoring}

GitLab utilise des structures de données internes pour mesurer différents aspects de lui-même. Ces fonctionnalités ne sont plus nécessaires si la surveillance est désactivée.

Pour désactiver ces fonctionnalités, accédez à la zone **Admin** de GitLab et désactivez la fonctionnalité Prometheus Metrics :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres > Statistiques et rapports**.
1. Développez **Métriques — Prometheus**.
1. Désactivez **Enable Prometheus Metrics**.
1. Sélectionnez **Sauvegarder les modifications**.

## Configuration avec toutes les modifications {#configuration-with-all-the-changes}

1. Si vous appliquez tout ce qui a été décrit jusqu'à présent, votre fichier `/etc/gitlab/gitlab.rb` doit contenir la configuration suivante :

   ```ruby
   puma['worker_processes'] = 0

   sidekiq['concurrency'] = 10

   prometheus_monitoring['enable'] = false

   gitlab_rails['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
   }

   gitaly['configuration'] = {
     concurrency: [
       {
         'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
         'max_per_repo' => 3,
       }, {
         'rpc' => "/gitaly.SSHService/SSHUploadPack",
         'max_per_repo' => 3,
       },
     ],
     cgroups: {
       repositories: {
         count: 2,
       },
       mountpoint: '/sys/fs/cgroup',
       hierarchy_root: 'gitaly',
       memory_bytes: 500000,
       cpu_shares: 512,
     },
   }
   gitaly['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000',
     'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
   }
   ```

1. Après avoir effectué toutes ces modifications, reconfigurez GitLab pour utiliser les nouveaux paramètres :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   Cette opération peut prendre un certain temps, car GitLab n'a pas fonctionné avec des paramètres conservateurs en matière de mémoire jusqu'à présent.

## Résultats de performance {#performance-results}

Après avoir appliqué la configuration ci-dessus, vous pouvez vous attendre à l'utilisation de mémoire suivante :

```plaintext
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       1.7Gi       151Mi        31Mi       132Mi       102Mi
Swap:         1.0Gi       153Mi       870Mi
```
