
# Development process

## Testing

Any change in the internal cookbook also requires specs.
It would be greatly appreciated if with any MR submitted, apart from testing
the specific feature/bug, more tests are written to increase the test coverage.

When in rush to fix something (eg. security issue, bug blocking the release),
writing specs can be skipped. However, an issue to implement the tests
*must be created and assigned* to the person that originally wrote the code.


# Development setup

To avoid building the packages for every change you do during development, it
is useful to setup a VM on which you can develop.

Once you get the VM running, download the package from
`https://about.gitlab.com/downloads/` and using the directions there finish the
package installation.

Once the package is installed, navigate to `/opt/gitlab/embedded/cookbooks` and
rename the `gitlab` directory which holds the internal omnibus-gitlab cookbook.

```
sudo mv /opt/gitlab/embedded/cookbooks/gitlab /opt/gitlab/embedded/cookbooks/gitlab.$(date +%s)
```

Clone the omnibus-gitlab repository from
`https://gitlab.com/gitlab-org/omnibus-gitlab.git` to a known location, for
example your home directory.

```
git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
```

Once the repository is cloned symlink the cookbook in the omnibus-gitlab
repository, for example:

```
sudo ln -s ~/omnibus-gitlab/files/gitlab-cookbooks/gitlab /opt/gitlab/embedded/cookbooks/gitlab
```

Now you can do the changes in the omnibus-gitlab repository, try the changes
right away and contribute back to omnibus-gitlab.
