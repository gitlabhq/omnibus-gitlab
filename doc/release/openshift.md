---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# OpenShift Omnibus GitLab Release Process

**`Note:`** This document is deprecated. We now recommend the official
Kubernetes Helm charts for OpenShift also. Check out [release documentation for
the charts](https://gitlab.com/charts/gitlab/blob/master/doc/development/release.md)
for details.

New GitLab templates for OpenShift are prepared as part of our [cloud image release process](README.md#updating-cloud-images).

## Update the template to latest GitLab release

Within the template we reference our Docker image. Go to <https://hub.docker.com/r/gitlab/gitlab-ce/tags>
and find the newest descriptive tag. e.g. `8.13.3-ce.0`

Then update the image stream in the template with the name and tag:

```json
{
  "kind": "ImageStream",
  "apiVersion": "v1",
  "metadata": {
    "name": "${APPLICATION_NAME}",
    "labels": {
      "app": "${APPLICATION_NAME}"
    }
  },
  "spec": {
    "tags": [
      {
        "name": "8.13.3", /* <-- Change this */
        "from": {
          "kind": "DockerImage",
          "name": "gitlab/gitlab-ce:8.13.3-ce.0" /* <-- Change this */
        }
      }
    ]
  }
},
```

And then also update the GitLab Deployment config to use the new tag in it's ImageChange trigger:

```json
{
  "type": "ImageChange",
  "imageChangeParams": {
    "automatic": true,
    "containerNames": [
      "gitlab-ce"
    ],
    "from": {
      "kind": "ImageStreamTag",
      "name": "${APPLICATION_NAME}:8.13.3" /* <-- Change this */
    }
  }
}
```

## Test

For setting up a OpenShift Origin development environment for testing see
[`doc/development/openshift/README.md`](../development/openshift/README.md).

Set up a new GitLab install using the updated template. Smoke test the install:

1. Login works
1. Create project succeeds
1. Readme can be created through the UI
1. Repo can be clone and pushed to over http

## Submit new Merge Request

Push your updated template into a New Merge request on GitLab.com against the master branch

## Notify

Once the Merge Request has been accepted, alert the `#gitlab-openshift` Slack channel that a new
version has been pushed to master. Effectively handing off the template to OpenShift for inclusion in the all-in-one.
