---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres de notification push mobile
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248026) dans GitLab 19.3 [avec les feature flags](https://docs.gitlab.com/administration/feature_flags/) nommés `mobile_push_registration_api`, `mobile_push_notifications_dispatch` et `mobile_push_notifications`. Fonctionnalité désactivée par défaut.

{{< /history >}}

GitLab peut envoyer des notifications push mobiles pour les tâches à faire via le service Apple Push Notification (APNs), en utilisant l'authentification par jeton de fournisseur Apple (p8). La livraison est entièrement ignorée lorsqu'aucune clé de signature n'est configurée.

La fonctionnalité côté serveur est contrôlée par des [feature flags](https://docs.gitlab.com/administration/feature_flags/) désactivés par défaut : `mobile_push_registration_api` contrôle l'[API d'abonnements aux notifications push mobiles](https://docs.gitlab.com/api/mobile_push_subscriptions/) auprès de laquelle les appareils s'inscrivent, et `mobile_push_notifications_dispatch` et `mobile_push_notifications` contrôlent la livraison. Les appareils ne peuvent pas s'inscrire et aucune notification push n'est envoyée tant qu'un administrateur n'a pas activé les trois.

Prérequis :

- Une [clé de signature du jeton de fournisseur APNs](https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns) (fichier `.p8`) issue d'un compte Apple Developer, accompagnée de son identifiant de clé et de l'identifiant d'équipe Apple Developer.

Pour configurer la livraison APNs :

1. Copiez la clé de signature `.p8` vers un chemin lisible par GitLab, par exemple `/etc/gitlab/mobile_push_apns_auth_key.p8`, et restreignez son accès :

   ```shell
   sudo chown git:root /etc/gitlab/mobile_push_apns_auth_key.p8
   sudo chmod 0400 /etc/gitlab/mobile_push_apns_auth_key.p8
   ```

   `/etc/gitlab` est lisible par tous les utilisateurs, donc sans le `chmod`, une simple copie laisse la clé de signature privée lisible par tous les utilisateurs locaux. La clé doit rester lisible par l'utilisateur `git` : une clé réservée à root réussit `gitlab-ctl reconfigure` (qui s'exécute en tant que `root`), mais interrompt silencieusement la livraison pour l'application (qui s'exécute en tant que `git`).

1. Ajoutez ce qui suit dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['mobile_push_apns_auth_key_path'] = "/etc/gitlab/mobile_push_apns_auth_key.p8"
   gitlab_rails['mobile_push_apns_key_id'] = "YOUR-APNS-KEY-ID"
   gitlab_rails['mobile_push_apns_team_id'] = "YOUR-APPLE-TEAM-ID"
   ```

   En option, définissez `gitlab_rails['mobile_push_apns_topic']` pour remplacer l'en-tête `apns-topic` envoyé pour les abonnements d'appareils qui ne comportent pas d'identifiant de bundle. Lorsqu'il n'est pas défini, le topic prend la valeur par défaut `com.gitlab-mobile.app`.

1. Enregistrez le fichier et exécutez `gitlab-ctl reconfigure`.

Le chemin de la clé d'authentification, l'identifiant de clé et l'identifiant d'équipe doivent tous être définis ensemble : `gitlab-ctl reconfigure` échoue si seulement certains d'entre eux sont définis. Si aucun fichier n'existe au chemin de clé configuré, la reconfiguration affiche un avertissement et la livraison APNs échoue jusqu'à ce que la clé soit placée à cet emplacement et soit lisible par l'utilisateur `git`.

L'enregistrement des appareils est exposé via l'[API d'abonnements aux notifications push mobiles](https://docs.gitlab.com/api/mobile_push_subscriptions/).
