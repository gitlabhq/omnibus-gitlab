---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Action Cable
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Action Cable est un moteur Rails qui gère les connexions websocket.

## Configuration de la taille du pool de workers {#configuring-the-worker-pool-size}

Action Cable utilise un pool de fils de discussion distinct par worker Puma. Le nombre de fils de discussion peut être configuré à l'aide de l'option `actioncable['worker_pool_size']`.
