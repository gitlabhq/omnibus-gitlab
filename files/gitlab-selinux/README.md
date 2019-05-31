# SELinux modules for GitLab

## RHEL / Centos 7

The following files are named by the GitLab version they were first
introduced. For example, `gitlab-7.2.0-ssh-keygen` maps to GitLab v7.2. Both
.te (Type Enforcement) and .pp (Project Policy) files are included.

For reference, we created the .pp files from the .te files by using the
following commands on CentOS:

```sh
checkmodule -M -m -o filename.mod filename.te
semodule_package -o filename.pp -m filename.mod
```

### rhel/7/gitlab-7.2.0-ssh-keygen.pp

GitLab handles SSH public keys and we want to verify whether users input valid
SSH keys using the ssh-keygen utility. Because ssh-keygen does not accept input
from standard input, we need to create a temporary file. This SELinux module
gives ssh-keygen permission to read the temporary file we create for it.

### rhel/7/gitlab-10.5.0-ssh-authorized-keys.pp

To support [fast SSH key lookups via the database]
(https://docs.gitlab.com/ee/administration/operations/fast_ssh_key_lookup.html)
GitLab needs additional permissions. This SELinux module gives sshd
permission to do the following:

* Write to /var/log/gitlab/gitlab-shell.log
* Connect to the internal API via unicorn on port 8080

Outside of the module, the gitlab-shell recipe also grants specific
permissions to read the files:

* /var/opt/gitlab/gitlab-shell/config.yml
* /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret

By default, SELinux allocates port 8080 to the http_cache_port_t context.
Note that if you have to change that port, you will have to create a custom
SELinux module to accommodate that.
