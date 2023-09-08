# Mattermost component upgrade test plan

<!-- Copy and paste the following into your MR description. -->
## Test plan

### Build tests

- [ ] Built on all supported platforms
- [ ] Ran `Trigger:ee-package` and then `qa-subset-test` as well as manual `qa-remaining-test-manual` CI jobs on `gitlab.com`.

### Fresh installation tests

Installed a Linux package created in the build system on a fresh OS installation
and ran the following actions, checks, and tests:

- [ ] Installed Linux package with the new Mattermost version:

  - [ ] Verified that package installation logs/output shows no errors.
  - [ ] Verified Mattermost version by running `/opt/gitlab/embedded/bin/mattermost version`.

- [ ] Edited `/etc/gitlab/gitlab.rb` and set:

  - `external_url`
  - `mattermost_external_url`

  Both URLs should point to the same system so that GitLab and Mattermost are co-located. Example:

  ```yaml
  external_url 'gitlab.example.com'
  mattermost_external_url 'mattermost.example.com'
  ```

- [ ] Ran `gitlab-ctl reconfigure`.
- [ ] Connected to `gitlab.example.com`.
- [ ] Navigated to `Admin>Settings>Network>Outbound requests` and added `mattermost.example.com` to `Local IP addresses and domain names that hooks and services can accesss` and clicked `Save changes`.
- [ ] Navigated to `mattermost.example.com`.
- [ ] Verified that single-sign on using GitLab credentials was working:

  1. Clicked on `or create and account with` GitLab.
  1. When presented with the `Authorize GitLab Mattermost to use your account?` page, clicked on `Authorize`.
     You should have landed on the `Select teams` page.

- [ ] Verified that when creating a group in GitLab, checking the box for **Create a Mattermost team for this group** also created a team in Mattermost and the GitLab user is a member of that team.
- [ ] Created a test project within the group created in the previous step and initialize with a `README`.

- [ ] Verified Mattermost slash command operation:
  - [ ] Enabled slash commands using [GitLab documentation](https://docs.gitlab.com/ee/user/project/integrations/mattermost_slash_commands.html#configure-automatically).
  - [ ] Tested slash commands by creating a new issue from the Mattermost instance. After following the prompt to re-authorize, the issue should have been successfully created in GitLab.

- [ ] Verified GitLab issue notification.

  - [ ] Configured incoming web hooks in Mattermost using the [GitLab Documentation](https://docs.gitlab.com/ee/user/project/integrations/mattermost.html). Note that you have to configure both Mattermost and GitLab.
  - [ ] Using the created web hook, followed the documentation for adding [notification support](https://docs.gitlab.com/ee/user/project/integrations/mattermost.html#configure-mattermost-to-receive-gitlab-notifications).
  - [ ] Created an issue in the test project. Verified that the notification for the issue appeared in Mattermost for the GitLab user.

### Upgrade installation tests

Install a Linux package from the previous, latest minor number release on a
fresh OS installation. Run the following actions, checks, and tests:

- [ ] Installed Linux package from the previous, latest minor number release:

  - [ ] Verified that package installation logs/output showed no errors.
  - [ ] Verified Mattermost version by running `/opt/gitlab/embedded/bin/mattermost version`.

- [ ] Edited `/etc/gitlab/gitlab.rb` and set:

  - `external_url`
  - `mattermost_external_url`

  Both URLs should point to the same system so that GitLab and Mattermost are co-located. Example:

  ```yaml
  external_url 'gitlab.example.com'
  mattermost_external_url 'mattermost.example.com'
  ```

- [ ] Ran `gitlab-ctl reconfigure`.
- [ ] Connected to `gitlab.example.com`.
- [ ] Navigated to `Admin>Settings>Network>Outbound requests` and added `mattermost.example.com` to `Local IP addresses and domain names that hooks and services can accesss` and clicked `Save changes`.
- [ ] Navigated to `mattermost.example.com`.
- [ ] Verified that single-sign on using GitLab credentials is working:

  1. Clicked on `or create and account with` GitLab.
  1. When presented with the `Authorize GitLab Mattermost to use your account?` page, clicked on `Authorize`.
  1. You should have landed on the `Select teams` page.

- [ ] Verified that when creating a group in GitLab, checking the box for **Create a Mattermost team for this group** also created a team in Mattermost and the GitLab user is a member of that team.
- [ ] Created a test project within the group created in the previous step and initialized with a `README`.

- [ ] Verified Mattermost slash command operation:

  - [ ] Enabled slash commands using [GitLab documentation](https://docs.gitlab.com/ee/user/project/integrations/mattermost_slash_commands.html#configure-automatically).
  - [ ] Tested slash commands by creating a new issue from the Mattermost instance. After following the prompt to re-authorize, the issue should have been successfully created in GitLab.

- [ ] Verified GitLab issue notification.

  - [ ] Configured incoming web hooks in Mattermost using the [GitLab Documentation](https://docs.gitlab.com/ee/user/project/integrations/mattermost.html). Note that you have to configure both Mattermost and GitLab.
  - [ ] Using the created web hook, followed the documentation for adding [notification support](https://docs.gitlab.com/ee/user/project/integrations/mattermost.html#configure-mattermost-to-receive-gitlab-notifications).
  - [ ] Created an issue in the test project. Verified that the notification for the issue appears in Mattermost for the GitLab user.

Upgrade GitLab with a Linux package created with the new Mattermost version. Run the
following actions, checks, and tests:

- [ ] Upgraded to package with new Mattermost version:

  - [ ] Verified that package installation logs/output shows no errors.
  - [ ] Verified Mattermost version by running `/opt/gitlab/embedded/bin/mattermost version`.

- [ ] Verified Mattermost slash command operation:

  - [ ] Tested slash commands by creating a new issue from the Mattermost instance. After following the prompt to re-authorize, the issue should have been successfully created in GitLab.

- [ ] Verified GitLab issue notification.

  - [ ] Created an issue in the test project. Verified that the notification for the issue appeared in Mattermost for the GitLab user.
