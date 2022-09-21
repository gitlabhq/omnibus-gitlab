---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrading Chef

Chef is a major part of `omnibus-gitlab`, and periodically needs to be updated. Follow these steps
to upgrade to the latest version and verify the functionality.

## Upgrade steps

1. Create a new branch in `omnibus-gitlab`

   ```shell
   git switch -c upgrade-chef-to-X
   ```

1. Update the appropriate software entries in `config/software/`. Change `default_version` to be the newer version we're upgrading to for:

    1. chef-bin
    1. chef-gem
    1. chef-zero
    1. ohai

1. Update entries in `Gemfile` to the new version. At a mininum, the `chef` and `ohai` entries will need to be updated.
1. Update the bundle

   1. If this is a major version upgrade

   ```shell
   bundle update chef ohai
   ```

   1. If this is a minor version upgrade

   ```shell
   bundle update chef ohai --conservative
   ```

   It may be necessary to chase down errors related to dependencies being upgraded

1. Commit the changes

   ```shell
   git add config/software/chef-{bin,gem,zero}.rb
   git add Gemfile{,.lock}
   git commit
   git push
   ```

1. Ensure the pipelines pass on GitLab.com
1. Trigger an EE package pipeline to ensure we get a `gitlab-qa` run
1. When available, trigger an HA validation job
1. Check QA jobs for the package pipeline, and the HA validation job, ensure pipelines are green, or any failures are unrelated.
1. Push to `omnibus-gitlab` on `dev.gitlab.org` and ensure the package builds on all platforms
1. Download a package to a dev environment, and verify you can upgrade from an older version of `omnibus-gitlab`, to the newer package
1. Verify a Geo installation is successful using the newer package

## Bonus points

1. Read through the Changelog and Release notes, identify any improvements, new features, or bug fixes which may apply to omnibus and open follow up issues
