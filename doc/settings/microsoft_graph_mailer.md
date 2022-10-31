---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Microsoft Graph Mailer settings **(FREE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8259) in GitLab 15.5.

If you would rather send application emails using [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http)
with [OAuth 2.0 client credentials flow](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow),
add the following configuration information to `/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.

```ruby
gitlab_rails['microsoft_graph_mailer_enabled'] = true

# The unique identifier for the user. To use Microsoft Graph on behalf of the user.
gitlab_rails['microsoft_graph_mailer_user_id'] = "YOUR_USER_ID"

# The directory tenant the application plans to operate against, in GUID or domain-name format.
gitlab_rails['microsoft_graph_mailer_tenant'] = "YOUR_TENANT_ID"

# The application ID that's assigned to your app. You can find this information in the portal where you registered your app.
gitlab_rails['microsoft_graph_mailer_client_id'] = "YOUR_CLIENT_ID"

# The client secret that you generated for your app in the app registration portal.
gitlab_rails['microsoft_graph_mailer_client_secret'] = "YOUR_CLIENT_SECRET_ID"

gitlab_rails['microsoft_graph_mailer_azure_ad_endpoint'] = "https://login.microsoftonline.com"

gitlab_rails['microsoft_graph_mailer_graph_endpoint'] = "https://graph.microsoft.com"
```
