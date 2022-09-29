---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Set up your development environment

Development of Omnibus GitLab can be done using an existing package available
from the [Downloads page](https://about.gitlab.com/install/). To know how to setup
a build environment to build these packages and use them, please read
[Setting up a Build Environment](../build/build_package.md#prepare-a-build-environment)

Choose one of the GitLab installation methods below. To provide isolation and
to prevent rebuilding of the package for each and every change, it is preferred
to use a container for development.

## Set up a container

1. Install Docker for your OS as per the [official Docker installation docs](https://docs.docker.com/install/).

1. Pull the GitLab CE nightly image:

   ```shell
   docker pull gitlab/gitlab-ce:nightly
   ```

1. Run the Docker image with a shell prompt:

   ```shell
   docker run -it --publish 443:443 --publish 80:80 --publish 22:22 gitlab/gitlab-ce:nightly bash
   ```

   This command runs Docker with the GitLab nightly image. You start with a
   bash prompt, where you run the following commands.

1. Initialize GitLab by first starting runsv, followed by `reconfigure`:

   ```shell
   /opt/gitlab/embedded/bin/runsvdir-start &
   gitlab-ctl reconfigure
   ```

   If you have sysctl errors after running `reconfigure`, there is a workaround in the
   [common installation problems doc](../troubleshooting.md#failed-to-modify-kernel-parameters-with-sysctl).

1. (Optional) Take a snapshot of your container, so you can revert to this image if required. Run these commands on the Docker host:

   ```shell
   docker ps # Find the container ID of our container.
   docker commit <container_id> gitlab_nightly_post_install
   ```

## Use an official nightly package

1. Get the GitLab CE nightly package from the [Nightly Build repository](https://packages.gitlab.com/gitlab/nightly-builds)
   and install it using the instructions given on that page.

   NOTE:
   On Ubuntu Xenial, you may have to install `tzdata`. This
   [issue is reported in #4769](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4679).

1. Configure and start GitLab.
1. Check if you can access the GitLab instance from your host browser on `<ip address of host>`.
1. Install the basic tools used for developing Omnibus GitLab:

   ```shell
   sudo apt-get install git
   ```

## Get the source of Omnibus GitLab

1. Get the source code of Omnibus GitLab from the [repository on GitLab.com](https://gitlab.com/gitlab-org/omnibus-gitlab):

   ```shell
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   ```

   We will be doing the development inside the `~/omnibus-gitlab` directory.

1. Instructing GitLab to apply the changes we make to the cookbooks.

   During development, we need the changes we make to the cookbooks to be
   applied immediately to the running GitLab instance. So, we have to configure
   GitLab to use those cookbooks instead of the ones shipped during
   installation. This involves backing up of the existing cookbooks directories
   and symlinking the directories where we make modifications to its location:

   ```shell
   cd ~/omnibus-gitlab/files/gitlab-cookbooks
   for i in $(ls); do
     mv "/opt/gitlab/embedded/cookbooks/${i}" "/opt/gitlab/embedded/cookbooks/${i}.$(date +%s)"
     ln -s "$(pwd)/${i}" "/opt/gitlab/embedded/cookbooks/${i}"
   done
   ```

   Now, you can make any necessary changes in the cookbooks inside `~/omnibus-gitlab/files/gitlab-cookbooks/`
   and run `sudo gitlab-ctl reconfigure` for those changes to take effect.

## Run GitLab QA Against Your Development Environment

You can run [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa) tests against your development instance.

This ensures that your new work is behaving as expected, and not breaking anything else. You can even add your own tests to QA to validate what you are working on.

1. Create a user account on your development instance for GitLab QA to use

   Then, from any machine that can reach your development instance:

1. Clone the [GitLab EE](https://gitlab.com/gitlab-org/gitlab) repository

   ```shell
   git clone git@gitlab.com:gitlab-org/gitlab.git
   ```

1. Change to the `qa` directory

   ```shell
   cd gitlab/qa
   ```

1. Install the required gems

   ```shell
   bundle install
   ```

1. Run the tests

   ```shell
   GITLAB_USERNAME=$USERNAME GITLAB_PASSWORD=$PASSWORD bundle exec bin/qa Test::Instance $DEV_INSTANCE_URL
   ```

## Run specific chefspec tests

You can also test your changes against the current tests (or to test your newly added tests).

1. Install `bundler` and `ruby-dev`, which are required to build the necessary gems:

   ```shell
   sudo apt install bundler ruby-dev
   ```

1. Change to the `omnibus-gitlab` directory:

   ```shell
   cd ~/omnibus-gitlab
   ```

1. Install the required gems inside the omnibus directory:

   ```shell
   /usr/bin/bundle install --path vendor/bundle
   ```

   If you use the GitLab Nightly Docker images, `/opt/gitlab/embedded/bin` is prepended to the `$PATH`, so using `bundle` alone uses the binary
   that is included as part of GitLab. That's why we use the absolute path to the system `bundle`.

1. Run your desired tests. The tests may need to run as root, as they need access to read the secrets file:

   ```shell
   sudo bundle exec rspec spec/<path_to_spec_file>
   ```

## Use chef-shell with `omnibus-gitlab` cookbooks

You can use [chef-shell](https://docs.chef.io/workstation/chef_shell/) to debug changes to the cookbooks in your instance.

As root in your development server run:

```shell
/opt/gitlab/embedded/bin/chef-shell -z -c /opt/gitlab/embedded/cookbooks/solo.rb -s -j /opt/gitlab/embedded/cookbooks/dna.json
```

## Use Customers Portal Staging in GitLab

To connect your GitLab instance to Customers Portal Staging, you can set the following
[custom environment variables](../settings/environment-variables.md#setting-custom-environment-variables)
in `/etc/gitlab/gitlab.rb` by supplying them in a `gitlab_rails['env']` hash. Set:

- `GITLAB_LICENSE_MODE` to `test`
- `CUSTOMER_PORTAL_URL` to `https://customers.staging.gitlab.com`

For example:

```ruby
gitlab_rails['env'] = {
    "GITLAB_LICENSE_MODE" => "test",
    "CUSTOMER_PORTAL_URL" => "https://customers.staging.gitlab.com"
}
```

## OpenShift GitLab Development Setup

See Omnibus GitLab [development setup](openshift/index.md) documentation.
