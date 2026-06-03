---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres de Microsoft Graph Mailer
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/8259) dans GitLab 15.5.

{{< /history >}}

Prérequis :

- Pour utiliser l'API Microsoft Graph afin d'envoyer des e-mails, vous devez d'abord [créer une application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) dans Azure Active Directory, et ajouter l'`Mail.Send` [autorisation d'application](https://learn.microsoft.com/en-us/graph/permissions-reference).
- Définissez les autorisations d'application sur **App-only access**. Assurez-vous que les autorisations ne sont pas définies sur **Delegated**.

Si vous préférez envoyer des e-mails d'application via [l'API Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http) avec le [flux d'informations d'identification client OAuth 2.0](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow), ajoutez les informations de configuration suivantes dans `/etc/gitlab/gitlab.rb` et exécutez `gitlab-ctl reconfigure`.

```ruby
# The originating email address for outgoing mail
gitlab_rails['gitlab_email_from'] = '<YOUR_ACCOUNT_EMAIL>'

# The reply-to email address
gitlab_rails['gitlab_email_reply_to'] = '<YOUR_ACCOUNT_EMAIL>'

gitlab_rails['microsoft_graph_mailer_enabled'] = true

# The unique identifier for the user. To use Microsoft Graph on behalf of the user.
gitlab_rails['microsoft_graph_mailer_user_id'] = "<YOUR_USER_ID>"

# The directory tenant the application plans to operate against, in GUID or domain-name format.
gitlab_rails['microsoft_graph_mailer_tenant'] = "<YOUR_TENANT_ID>"

# The application ID that's assigned to your app. You can find this information in the portal where you registered your app.
gitlab_rails['microsoft_graph_mailer_client_id'] = "<YOUR_CLIENT_ID>"

# The client secret that you generated for your app in the app registration portal.
gitlab_rails['microsoft_graph_mailer_client_secret'] = "<YOUR_CLIENT_SECRET_ID>"

gitlab_rails['microsoft_graph_mailer_azure_ad_endpoint'] = "https://login.microsoftonline.com"

gitlab_rails['microsoft_graph_mailer_graph_endpoint'] = "https://graph.microsoft.com"
```

## Dépannage {#troubleshooting}

### `ErrorSendAsDenied` {#errorsendasdenied}

Le message d'erreur complet est :

```plaintext
"ErrorSendAsDenied","message":"The user account which was used to submit this request does not have the right to send mail on behalf of the specified sending account., Cannot submit message."
```

Pour résoudre cette erreur :

1. Vérifiez que vos autorisations d'API sont correctes en consultant l'[autorisation d'application](https://learn.microsoft.com/en-us/graph/permissions-reference).
1. Définissez les champs suivants sur l'adresse e-mail du compte que vous utilisez :
   - `gitlab_rails['gitlab_email_from']`.
   - `gitlab_rails['gitlab_email_reply_to']`.

En dehors des autorisations, cette erreur est parfois causée par le fait que le serveur n'autorise pas l'utilisation de la valeur par défaut `gitlab_email_from`. Vous devez définir la valeur sur l'adresse e-mail du compte avec lequel vous vous authentifiez.

### `Tail logs` {#tail-logs}

Pour le dépannage, utilisez la commande `tail logs` pour afficher les mises à jour en direct des journaux GitLab :

```ruby
# Tail all logs for the application
sudo gitlab-ctl tail

# Tail logs for an application sub-directory
sudo gitlab-ctl tail gitlab-rails

# Tail logs for an individual file in the application
sudo gitlab-ctl tail nginx/gitlab_error.log
```

Pour arrêter l'une de ces commandes, appuyez sur <kbd>Control</kbd>+<kbd>C</kbd>.
