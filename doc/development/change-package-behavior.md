---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Add or change behavior during package install and upgrade

## Test changes during install/upgrade

If you are working on changes to the install/upgrade process, and not the reconfigure process itself, you can use the [scripts/repack-deb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/scripts/repack-deb) tool to quickly repack an existing GitLab deb with changes from your local branch. It will repack the existing deb file into a new deb containing the local content from

- `config/templates/package-scripts`
- `files/gitlab-cookbook/`
- `files/gitlab-ctl-commands`
- `files/gitlab-ctl-commands-ee`
