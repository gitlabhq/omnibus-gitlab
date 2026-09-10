---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Artifact Registry
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

> [!warning]
> Artifact Registry is an experimental feature. The service itself runs on
> GitLab.com only, and these settings are subject to change. They exist so a
> GitLab Self-Managed instance can connect to that service in a hybrid
> deployment. Do not treat Artifact Registry as generally available for
> GitLab Self-Managed.

Artifact Registry runs as a separate service. The Linux package does not install
or package it. These settings configure GitLab Rails to connect to an Artifact
Registry service that you run yourself. Use them for hybrid deployments, where
GitLab Rails runs on a Linux package installation and Artifact Registry runs
elsewhere.

## Configure the connection

To point GitLab at an Artifact Registry service, edit `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['artifact_registry']['api_url'] = 'https://artifact-registry.example.com'
```

Then reconfigure GitLab:

```shell
sudo gitlab-ctl reconfigure
```

This renders the `artifact_registry.api_url` key into `gitlab.yml`. When
`api_url` is unset, GitLab renders no `artifact_registry` section and does not
connect to any Artifact Registry service.

## Configure the service token

The Artifact Registry internal API authenticates with a shared service token.
The file that holds it is operator-supplied. The Linux package does not create,
generate, or manage it.

Write the token that the Artifact Registry service accepts to the file, then
restrict access to it:

```shell
sudo mkdir -p /etc/gitlab/artifact-registry
sudo install -m 0400 -o git -g root /dev/stdin /etc/gitlab/artifact-registry/.gitlab_artifact_registry_secret <<< 'your-service-token'
```

`/etc/gitlab` is world-readable, so a plain copy leaves the token readable by
every local user. The file must stay readable by the `git` user. A root-only
file passes `gitlab-ctl reconfigure`, which runs as `root`, but silently breaks
the service path for the application, which runs as `git`.

Then point GitLab at it:

```ruby
gitlab_rails['artifact_registry']['service_token_file'] = '/etc/gitlab/artifact-registry/.gitlab_artifact_registry_secret'
```

After reconfiguring, GitLab renders the token file path into `gitlab.yml` under
`artifact_registry.service_token.secret_file`. When the token file is unset,
GitLab renders `api_url` alone and the service path fails closed until you
configure the token.
