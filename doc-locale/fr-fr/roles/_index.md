---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rôles de haute disponibilité
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les packages Linux incluent divers composants/services logiciels pour prendre en charge l'exécution de GitLab dans une configuration de haute disponibilité. Par défaut, certains de ces services de support sont désactivés et GitLab est configuré pour s'exécuter en tant qu'installation à nœud unique. Chaque service peut être activé ou désactivé à l'aide des paramètres de configuration dans `/etc/gitlab/gitlab.rb`, mais l'introduction de `roles` vous permet d'activer facilement un groupe de services et fournit une meilleure configuration par défaut en fonction des rôles de haute disponibilité que vous avez activés.

## Ne spécifier aucun rôle (la configuration par défaut) {#not-specifying-any-roles-the-default-configuration}

Lorsque vous ne configurez pas GitLab avec des rôles, GitLab active les services par défaut pour une installation à nœud unique. Cela inclut des éléments tels que PostgreSQL, Redis, Puma, Sidekiq, Gitaly, GitLab Workhorse, NGINX, etc.

Ceux-ci peuvent toujours être activés/désactivés individuellement par les paramètres dans votre `/etc/gitlab/gitlab.rb`.

## Spécifier des rôles {#specifying-roles}

Les rôles sont transmis sous forme de tableau dans `/etc/gitlab/gitlab.rb`

Exemple de spécification de plusieurs rôles :

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
```

Exemple de spécification d'un seul rôle :

```ruby
roles ['geo_primary_role']
```

## Rôles {#roles}

La majorité des rôles suivants ne fonctionneront que sur une [GitLab Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/), c'est-à-dire un package Linux `gitlab-ee`. Cela sera mentionné à côté de chaque rôle.

### Rôle Application GitLab {#gitlab-app-role}

- `application_role` (`gitlab-ce`/`gitlab-ee`)

  Le rôle Application GitLab est utilisé pour configurer une instance où seul GitLab s'exécute. Les services Redis, PostgreSQL et Consul sont désactivés par défaut.

### Rôles du serveur Redis {#redis-server-roles}

La documentation sur l'utilisation des rôles Redis est disponible dans [Configuring Redis for Scaling](https://docs.gitlab.com/administration/redis/)

- `redis_sentinel_role` (`gitlab-ee`)

  Active le service sentinel sur la machine,

  *Par défaut, n'active aucun autre service.*

- `redis_master_role` (`gitlab-ee`)

  Active le service Redis et la surveillance, et permet de configurer le mot de passe maître

  *Par défaut, n'active aucun autre service.*

- `redis_replica_role` (`gitlab-ee`)

  Active le service Redis et la surveillance

  *Par défaut, n'active aucun autre service.*

### Rôles GitLab Geo {#gitlab-geo-roles}

Les rôles GitLab Geo sont utilisés pour la configuration des sites GitLab Geo. Consultez la [Documentation de configuration de Geo](https://docs.gitlab.com/administration/geo/setup/) pour les étapes de configuration.

- `geo_primary_role` (`gitlab-ee`)

  Ce rôle :

  - Configure une base de données PostgreSQL à nœud unique en tant que leader pour la réplication en streaming.
  - Empêche la mise à niveau automatique de PostgreSQL car cela nécessite un temps d'arrêt de la réplication en streaming vers les sites secondaires Geo.
  - Active tous les services GitLab à nœud unique, notamment NGINX, Puma, Redis et Sidekiq. Si vous séparez des services, vous devez désactiver explicitement les services indésirables dans `/etc/gitlab/gitlab.rb`. Par conséquent, ce rôle n'est utile que sur un PostgreSQL à nœud unique dans un site principal Geo.
  - Ne peut pas être utilisé pour configurer un cluster PostgreSQL dans un site principal Geo. À la place, consultez [Réplication de base de données multi-nœuds Geo](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication).

  Par défaut, active les services GitLab standard à nœud unique, notamment NGINX, Puma, Redis et Sidekiq.

- `geo_secondary_role` (`gitlab-ee`)

  - Configure la base de données de réplica secondaire en lecture seule pour la réplication entrante.
  - Configure la connexion Rails à la base de données de suivi Geo.
  - Active la base de données de suivi Geo `geo-postgresql`.
  - Active le curseur de journal Geo `geo-logcursor`.
  - Désactive les migrations de base de données automatiques sur la base de données de réplica en lecture seule pendant la reconfiguration.
  - Réduit le nombre de workers Puma pour économiser de la mémoire pour d'autres services.
  - Définit `gitlab_rails['enable'] = true`.

  Ce rôle est destiné à être utilisé dans un site secondaire Geo s'exécutant sur un seul nœud. Si vous utilisez ce rôle dans un site Geo avec plusieurs nœuds, les services indésirables devront être explicitement désactivés dans `/etc/gitlab/gitlab.rb`. Consultez [Geo pour plusieurs nœuds](https://docs.gitlab.com/administration/geo/replication/multiple_servers/).

  Ce rôle ne doit pas être utilisé pour configurer un cluster PostgreSQL dans un site secondaire Geo. À la place, consultez [Réplication de base de données multi-nœuds Geo](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication).

  Par défaut, active tous les services par défaut de GitLab à nœud unique, notamment NGINX, Puma, Redis et Sidekiq.

### Rôles de surveillance {#monitoring-roles}

Les rôles de surveillance sont utilisés pour configurer la surveillance des installations. Pour plus d'informations, consultez la [documentation sur la surveillance](https://docs.gitlab.com/administration/monitoring/prometheus/).

- `monitoring_role` (`gitlab-ce`/`gitlab-ee`)

  Configure un serveur de surveillance centralisé pour collecter des métriques et fournir des tableaux de bord.

  Active Prometheus et Alertmanager.

### Rôles PostgreSQL {#postgresql-roles}

La documentation sur l'utilisation des rôles PostgreSQL est disponible dans [Configuring PostgreSQL for Scaling](https://docs.gitlab.com/administration/postgresql/)

- `postgres_role` (`gitlab-ce`/`gitlab-ee`)

  Active le service PostgreSQL sur la machine

  *Par défaut, n'active aucun autre service.*

- `patroni_role` (`gitlab-ee`)

  Active les services PostgreSQL, Patroni et Consul sur la machine

  *Par défaut, n'active aucun autre service.*

- `pgbouncer_role` (`gitlab-ee`)

  Active les services PgBouncer et Consul sur la machine

  *Par défaut, n'active aucun autre service.*

- `consul_role` (`gitlab-ee`)

  Active le service Consul sur la machine

  *Par défaut, n'active aucun autre service.*

### Rôles GitLab Pages {#gitlab-pages-roles}

Les rôles GitLab Pages sont utilisés pour configurer GitLab Pages. Pour plus d'informations, consultez la [documentation d'administration de GitLab Pages](https://docs.gitlab.com/administration/pages/)

- `pages_role` (`gitlab-ce`/`gitlab-ee`)

  Configure le serveur avec une instance GitLab Pages.

  *Par défaut, n'active aucun autre service.*

### Rôles Sidekiq {#sidekiq-roles}

Les rôles Sidekiq sont utilisés pour configurer Sidekiq. Pour plus d'informations, consultez la [documentation d'administration de Sidekiq](https://docs.gitlab.com/administration/sidekiq/)

- `sidekiq_role` (`gitlab-ce`/`gitlab-ee`)

  Configure le serveur avec le service Sidekiq.

  *Par défaut, n'active aucun autre service.*

### Rôles Gitaly {#gitaly-roles}

Les rôles Gitaly sont utilisés pour configurer les services Gitaly. Pour plus d'informations, consultez la [documentation Gitaly](https://docs.gitlab.com/administration/gitaly/)

- `gitaly_role` (`gitlab-ce`/`gitlab-ee`)

  Configure le serveur avec le service Gitaly.

  *Par défaut, n'active aucun autre service.*
