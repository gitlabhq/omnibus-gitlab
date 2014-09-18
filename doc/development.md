# Development setup

To avoid building the packages for every change you do during development, it is useful to setup a VM on which you can develop.

Once you get the VM running, download the package from `https://about.gitlab.com/downloads/` and using the directions there
finish the package installation.

Once the package is installed, navigate to `/opt/gitlab/embedded/cookbooks` and remove the `gitlab` directory which holds the internal omnibus-gitlab cookbook.

Clone the omnibus-gitlab repository from `https://gitlab.com/gitlab-org/omnibus-gitlab.git` to a known location, for example `/home/`.

Once the repository is cloned symlink the cookbook in the omnibus-gitlab repository, for example:

```
ln -s /home/omnibus-gitlab/files/gitlab-cookbooks/gitlab /opt/gitlab/embedded/cookbooks
```

Now you can do the changes in the omnibus-gitlab repository, try the changes right away and contribute back to omnibus-gitlab.
