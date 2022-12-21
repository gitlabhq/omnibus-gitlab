---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Microsoft Graph Mailer settings **(FREE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8259) in GitLab 15.5.

Prerequisites:

- To use the Microsoft Graph API to send mails, you must first
  [create an application](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
  in the Azure Active Directory, and add the `Mail.Send`
  [application permission](https://learn.microsoft.com/en-us/graph/permissions-reference).
- Set the application permissions to **App-only access**. Make sure the permissions are not set to **Delegated**.

If you would rather send application emails using [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http)
with [OAuth 2.0 client credentials flow](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow),
add the following configuration information to `/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.

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

## Troubleshooting

### `ErrorSendAsDenied`

The full error message is:

```plaintext
"ErrorSendAsDenied","message":"The user account which was used to submit this request does not have the right to send mail on behalf of the specified sending account., Cannot submit message."
```

To resolve this error:

1. Verify your API permissions are correct by reviewing the [application permission](https://learn.microsoft.com/en-us/graph/permissions-reference).

1. Set the following fields to the email address for the account you're using:
   - `gitlab_rails['gitlab_email_from']`.
   - `gitlab_rails['gitlab_email_reply_to']`.

Other than permissions, this error is sometimes caused because the server does not allow the default `gitlab_email_from` value to be used. You should set the value to the email address for the account you're authenticating with.
 
### `Tail logs`

For troubleshooting, use the `tail logs` command to view live GitLab log updates:

```ruby
# Tail all logs for the application
sudo gitlab-ctl tail

# Tail logs for an application sub-directory
sudo gitlab-ctl tail gitlab-rails

# Tail logs for an individual file in the application
sudo gitlab-ctl tail nginx/gitlab_error.log
```

To stop any of these commands, press <kbd>Control</kbd>+<kbd>C</kbd>.
