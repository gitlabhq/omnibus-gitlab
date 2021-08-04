---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# omnibus-mirror

In order to minimize the dependency on external resources during our build and release process, we maintain a mirror of various software dependencies within GitLab resources.

The system consists of two groups, one on GitLab.com, and the other on `dev.gitlab.org`

1. [GitLab.com projects](https://gitlab.com/gitlab-org/build/omnibus-mirror)

   1. Pull mirrors of the upstream source, and push mirrors to the corresponding `dev.gitlab.org` project.
   1. Publically available. Should be available to the `trigger-package` pipeline, as well as community developers for building custom `omnibus-gitlab` packages

1. [`dev.gitlab.org` projects](https://dev.gitlab.org/omnibus-mirror)

   1. Pipelines on `dev.gitlab.org` use these projects to build `omnibus-gitlab` projects. This includes the package releases, as well as builds used by GitLab Team members to build custom `omnibus-gitlab` packages for all supported platforms.

## Adding a project

1. Log into GitLab.com as the `gitlab-omnibus-mirror-bot`. Login details are in the Build vault in 1Password
1. Click on **New Project** to create a project
   1. **Project name**: usually should match the upstream name
   1. **Project URL**: Select `gitlab-org/build/omnibus-mirror` from the **Groups** sub-group in the drop-down
   1. **Visibility Level**: Set this to **Public**
   1. Disable any options that would create files, such as initializing with a `README.md`
   1. Leave the remaining options as their default, and click on **Create project**
1. Set up the pull mirror
   1. Click **Settings -> Repository** in the left hand menu
   1. Click **Expand** next to the **Mirroring repositories** option
   1. Set **Git repository URL** to the upstream URL we'll be mirroring
   1. Change **Mirror direction** to **Pull**
   1. Select the **Overwrite diverged branches** option
   1. Click **Mirror repository** to add the pull mirror. Depending on the size of the repository, this can take a few minutes to run
   1. Leave this page open as you will need it later
1. Log into `dev.gitlab.org` as the `build_mirror_bot`. Login details are in the Build vault in 1Password
1. Click on **New Project** to create a project
   1. **Project name**: usually should match the upstream name
   1. **Project URL**: Select `omnibus-mirror` from the **Groups** sub-group in the drop-down
   1. **Visibility Level**: Set this to **Private**
   1. Leave the remaining options as their default and click on **Create project**
1. Enable the `omnibus-builder` deploy key
   1. Navigate to **Settings -> Repository**
   1. Click on **Expand** next to the **Deploy Keys** section
   1. Click the **Privately accessible deploy keys** tab
   1. Find the `omnibus-builder deploy key` and click on the **Enable** button next to it
1. Setup the push mirror
   1. Return to the **Mirroring repositories** page for the GitLab.com project
   1. In **Git repository URL** enter the path to the `dev.gitlab.org` with `build_mirror_bot@` inserted between `https://` and `dev.gitlab.org`
   1. In **Password** enter the `PAT` from the **Build Team Mirror Bot** entry in the **Build** vault in 1 Password
   1. Disable any options that would create files, such as initializing with a `README.md`
   1. Leave the remaining options as their default, and click on **Mirror repository**
   1. Click the **Update Now** button to trigger initial mirroring
