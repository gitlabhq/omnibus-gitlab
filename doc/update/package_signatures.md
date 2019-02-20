# Package Signatures

This document will provide methods for verifying the signatures of GitLab produced
packages, both manually and automatically where supported.

## RPM based distributions

The RPM format contains a full implementation of GPG signing functionality, and
thus is fully integrated with the package management systems based upon that
format. There are two methods of verification.

### Verify GitLab public key is present

To verify a package on an RPM based distribution, we'll need to ensure
that the GitLab, Inc. public key is present in the `rpm` tool's keychain.

Run `rpm -q gpg-pubkey-f27eab47-5980fed7 --qf '%{name}-%{version}-%{release} --> %{summary}\n'`. This will produce either the information on
the public key, or `package gpg-pubkey-f27eab47 is not installed`. If the key is
not present, perform the following steps:

```
rpm --import https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
```

### Verify if signature check is active

The simplest method of checking if package signature checking is active on an existing install is to compare the content of the repository file in use.

* Check if the repository file exist: `file /etc/yum.repos.d/gitlab_gitlab-ce.repo`
* Check that signature checking is active: `grep gpgcheck /etc/yum.repos.d/gitlab_gitlab-ce.repo` should output
    ```
    repo_gpgcheck=1
    gpgcheck=1
    ```
    or
    ```
    repo_gpgcheck=1
    pkg_gpgcheck=1
    ```
If the file does not exist, you don't have the repository installed. If the file exists, but the output shows `gpgpcheck=0`, then you will need to edit that value to enable it, as below.

### Enable Automatic Verification

The `rpm` tool and related package managers (`yum`,`zypper`) directly support the automatic verification of packages without intervention. If you used the automated repository configuration script after signed packages became available, then you will have no additional steps required. If you installed prior to the release of signed packages, you can either make the necessary changes, or re-run the automatic repository configuration script as found on the [Installation][install] page.

#### Yum (RedHat, CentOS)
1. Enable GPG checking of the packages
   ```
   # sed -i'' 's/^gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/gitlab_gitlab-ce.repo
   ```

1. Add the package signing public key to the `gpgkey` list:
   Edit `/etc/yum.repos.d/gitlab_gitlab-ce.repo`, changing `gpgkey` to read:
   ```
   gpgkey=https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey
           https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   ```

1. Tell `yum` to refresh the cache for the repository
   ```
   # yum -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ce'
   ```

#### Zypper (SuSE/SLES)
1. Enable GPG checking of the packages
   ```
   # sed -i'' 's/pkg_gpgcheck=0/pkg_gpgcheck=1/' /etc/zypp/repos.d/gitlab_gitlab-ce.repo
   ```

1. Add the package signing public key to the `gpgkey` list:
   Edit `/etc/zypp/repos.d/gitlab_gitlab-ce.repo`, changing `gpgkey` to read:
   ```
   gpgkey=https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey
           https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   ```

1. Tell `zypper` to refresh the repository and import the keys
   ```
   # zypper --gpg-auto-import-keys refresh gitlab_gitlab-ce
   ```

### Manual Verification

Once the public key is confirmed present, an RPM package can be manually verified with `rpm --checksig gitlab-xxx.rpm`.

## DEB based distributions

The DEB format does not officially contain a default and included method for signing packages. At GitLab, we have chosen to implement the standard for `debsig` which is well documented, while not enabled by default on most distributions.

### Manual Verification

Manual verification of DEB packages signed with `debsigs` can be performed in two ways: using `debsig-verify` after configuring the necessary `debsigs` policy and keyring, or manually checking the contained `_gpgorigin` file with GnuPG.

#### Manually verify with GnuPG

The `debsig-verify` package has a [slew of dependencies](https://packages.debian.org/sid/devel/debsig-verify) that a user may not wish to install. To verify the `debsigs` based signature without installing `debsig-verify` and dependencies, a user can complete the following manual steps:

1. Download and import the package signing public key
   ```
   $ curl -JLO https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   $ gpg --import gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   ```

1. Extract the signature file (`_gpgorigin`)
   ```
   $ ar x gitlab-ce-xxx.deb _gpgorigin
   ```

1. Verify the signature matches the content
   ```
   $ ar p gitlab-xxx.deb debian-binary control.tar.gz data.tar.gz | gpg --verify _gpgorigin -
   ```

The output of the final command should appear as such:

```
$ ar p gitlab-xxx.deb debian-binary control.tar.gz data.tar.gz | gpg --verify _gpgorigin -
gpg: Signature made Tue Aug 01 22:21:11 2017 UTC
gpg:                using RSA key DBEF89774DDB9EB37D9FC3A03CFCF9BAF27EAB47
gpg:                issuer "support@gitlab.com"
gpg: Good signature from "GitLab, Inc. <support@gitlab.com>" [unknown]
Primary key fingerprint: DBEF 8977 4DDB 9EB3 7D9F  C3A0 3CFC F9BA F27E AB47
```

#### Configuring debsigs

Configuring a policy and keyring for `debsigs` can be complicated, so GitLab provides `gitlab-debsigs.sh` as a scripted method of configuration.

To use this script, you will need to download the public key and the script.
```
curl -JLO  https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
curl -JLO https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/scripts/gitlab-debsigs.sh
chmod +x gitlab-debsigs.sh
sudo ./gitlab-debsigs.sh gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
```


#### Verify with `debsig-verify`

To make use of `debsig-verify`, perform the steps in [Configuring debsigs](#configuring-debsigs) and install the `debsig-verify` package.

`debsig-verify gitlab-xxx.deb`


[install]: https://about.gitlab.com/installation/
