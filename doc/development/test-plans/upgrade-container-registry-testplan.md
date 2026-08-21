---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `container-registry` component upgrade
---

Copy the following test plan to a comment of the merge request
that upgrades the component.

````markdown
## Test plan

- [ ] Checked container-registry [changelog](https://gitlab.com/gitlab-org/container-registry/-/blob/master/CHANGELOG.md) for potential breaking changes.
- [ ] Start a new pipeline and trigger `Trigger::ee-package`.
- [ ] Run `qa-subset-test`.
- [ ] Test the component:
  - [ ] Install the GitLab omnibus package in a VM with TLS (HTTPS).
  - [ ] Check the container-registry package version.

    ```shell
    /opt/gitlab/embedded/bin/registry --version
    ```

  - [ ] Check package registry works.
    - [ ] Configure GitLab with container registry enabled by adding to `/etc/gitlab/gitlab.rb`:

      ```ruby
      external_url 'https://<gitlab_url>'
      registry_external_url '<external_url>:5050'
      ```
      > [!NOTE] You may need to configure your cloud firewall to allow port 5050 through. Example for `GCP`:
      >
      > ```shell
      > gcloud compute firewall-rules create allow-gitlab-registry \
      >   --allow tcp:5050 \
      >   --source-ranges 0.0.0.0/0
      > ```

    - [ ] Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

    - [ ] Verify container registry is running:

      ```shell
      sudo gitlab-ctl status registry
      ```

    - [ ] Create a project in GitLab.
    - [ ] Push image.

      ```shell
      podman login
      podman pull hello-world
      podman tag hello-world <gitlab_url>:5050/<user>/<project>/hello-world:latest
      podman push <gitlab_url>:5050/<user>/<project>/hello-world:latest
      ```

    - [ ] Pull image
      ```shell
      podman pull <gitlab_url>:5050/<user>/<project>/hello-world:latest
      ```
````
