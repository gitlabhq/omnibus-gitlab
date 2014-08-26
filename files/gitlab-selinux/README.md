# SELinux modules for GitLab

## RHEL / Centos 7

rhel/7/gitlab-7.2.0-ssh-keygen.pp

GitLab handles SSH public keys and we want to verify whether users input valid
SSH keys using the ssh-keygen utility. Because ssh-keygen does not accept input
from standard input, we need to create a temporary file. This SELinux module
gives ssh-keygen permission to read the temporary file we create for it.
