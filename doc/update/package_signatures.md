# Cryptographic details related to `omnibus-gitlab` packages

GitLab uses a [packagecloud](https://packages.gitlab.com) instance to share the
different OS packages it offers, and uses various cryptographic methods to
ensure the integrity of these packages. This page serves to provide details
regarding these methods.

## Package repository metadata signing keys

The apt and yum repositories on GitLab's packagecloud instance uses a GPG key to
sign their metadata. This key is automatically installed by the repo setup
script specified in the installation instructions.

### Current key

| Key Attribute | Value                                                |
| ------------- | ---------------------------------------------------- |
| Name          | `GitLab B.V.`                                        |
| EMail         | `packages@gitlab.com`                                |
| Comment       | `package repository signing key`                     |
| Fingerprint   | `F640 3F65 44A3 8863 DAA0  B6E0 3F01 618A 5131 2F3F` |
| Expiry        | `2022-03-02`                                         |

This key is active from **2020-04-06**. Existing users who already have
configured GitLab's apt/yum package repositories will have to fetch and add this
key to their trusted keyring again to continue installing packages from those
repositories without apt/yum complaining about mismatches, which is described
below.

#### Fetching new keys before 2020-04-06

```shell
# Download the new key
curl https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab_new_gpg.key -o /tmp/omnibus_gitlab_gpg.key

# Import the key
## Debian/Ubuntu/Raspbian
$ sudo apt-key add /tmp/omnibus_gitlab_gpg.key

# CentOS/OpenSUSE/SLES
$ sudo rpm --import /tmp/omnibus_gitlab_gpg.key
```

#### Fetching new keys after 2020-04-06

To fetch the latest repository signing key, users can run the `curl` command
used to add GitLab repository, as mentioned in the [install page](https://about.gitlab.com/install/),
again. It will fetch the new key and add it to the user's keyring.

Or, users can manually fetch and add the new key using the following commands

```shell
# Download the new key
curl https://packages.gitlab.com/gpg.key -o /tmp/omnibus_gitlab_gpg.key

# Import the key
## Debian/Ubuntu/Raspbian
$ sudo apt-key add /tmp/omnibus_gitlab_gpg.key

# CentOS/OpenSUSE/SLES
$ sudo rpm --import /tmp/omnibus_gitlab_gpg.key
```

### Previous keys

| Sl. No. | Key ID                                               | Expiry Date  |
| ------- | ---------------------------------------------------- | ------------ |
| 1       | `1A4C 919D B987 D435 9396  38B9 1421 9A96 E15E 78F4` | `2020-04-15` |

## Package Signatures

This document will provide methods for verifying the signatures of GitLab produced
packages, both manually and automatically where supported.

### RPM based distributions

The RPM format contains a full implementation of GPG signing functionality, and
thus is fully integrated with the package management systems based upon that
format. There are two methods of verification.

#### Verify GitLab public key is present

To verify a package on an RPM based distribution, we'll need to ensure
that the GitLab, Inc. public key is present in the `rpm` tool's keychain.

Run `rpm -q gpg-pubkey-f27eab47-5cc36020 --qf '%{name}-%{version}-%{release} --> %{summary}\n'`. This will produce either the information on
the public key, or `package gpg-pubkey-f27eab47 is not installed`. If the key is
not present, perform the following steps:

```shell
rpm --import https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
```

#### Verify if signature check is active

The simplest method of checking if package signature checking is active on an existing install is to compare the content of the repository file in use.

- Check if the repository file exist: `file /etc/yum.repos.d/gitlab_gitlab-ce.repo`
- Check that signature checking is active: `grep gpgcheck /etc/yum.repos.d/gitlab_gitlab-ce.repo` should output

  ```plaintext
  repo_gpgcheck=1
  gpgcheck=1
  ```

  or

  ```plaintext
  repo_gpgcheck=1
  pkg_gpgcheck=1
  ```

If the file does not exist, you don't have the repository installed. If the file exists, but the output shows `gpgpcheck=0`, then you will need to edit that value to enable it, as below.

#### Enable Automatic Verification

The `rpm` tool and related package managers (`yum`,`zypper`) directly support the automatic verification of packages without intervention. If you used the automated repository configuration script after signed packages became available, then you will have no additional steps required. If you installed prior to the release of signed packages, you can either make the necessary changes, or re-run the automatic repository configuration script as found on the [Installation](https://about.gitlab.com/install/) page.

##### Yum (RedHat, CentOS)

1. Enable GPG checking of the packages

   ```shell
   sudo sed -i'' 's/^gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/gitlab_gitlab-ce.repo
   ```

1. Add the package signing public key to the `gpgkey` list:
   Edit `/etc/yum.repos.d/gitlab_gitlab-ce.repo`, changing `gpgkey` to read:

   ```plaintext
   gpgkey=https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey
           https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   ```

1. Tell `yum` to refresh the cache for the repository

   ```shell
   sudo yum -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ce'
   ```

##### Zypper (SuSE/SLES)

1. Enable GPG checking of the packages

   ```shell
   sudo sed -i'' 's/pkg_gpgcheck=0/pkg_gpgcheck=1/' /etc/zypp/repos.d/gitlab_gitlab-ce.repo
   ```

1. Add the package signing public key to the `gpgkey` list:
   Edit `/etc/zypp/repos.d/gitlab_gitlab-ce.repo`, changing `gpgkey` to read:

   ```plaintext
   gpgkey=https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey
           https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   ```

1. Tell `zypper` to refresh the repository and import the keys

   ```shell
   sudo zypper --gpg-auto-import-keys refresh gitlab_gitlab-ce
   ```

#### Manual Verification

Once the public key is confirmed present, an RPM package can be manually verified with `rpm --checksig gitlab-xxx.rpm`.

### DEB based distributions

The DEB format does not officially contain a default and included method for signing packages. At GitLab, we have chosen to implement the standard for `debsig` which is well documented, while not enabled by default on most distributions.

#### Manual Verification

Manual verification of DEB packages signed with `debsigs` can be performed in two ways: using `debsig-verify` after configuring the necessary `debsigs` policy and keyring, or manually checking the contained `_gpgorigin` file with GnuPG.

##### Manually verify with GnuPG

The `debsig-verify` package has a [slew of dependencies](https://packages.debian.org/sid/devel/debsig-verify) that a user may not wish to install. To verify the `debsigs` based signature without installing `debsig-verify` and dependencies, a user can complete the following manual steps:

1. Download and import the package signing public key

   ```shell
   curl -JLO https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   gpg --import gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
   ```

1. Extract the signature file (`_gpgorigin`)

   ```shell
   ar x gitlab-ce-xxx.deb _gpgorigin
   ```

1. Verify the signature matches the content

   ```shell
   ar p gitlab-xxx.deb debian-binary control.tar.gz data.tar.gz | gpg --verify _gpgorigin -
   ```

The output of the final command should appear as such:

```shell
$ ar p gitlab-xxx.deb debian-binary control.tar.gz data.tar.gz | gpg --verify _gpgorigin -
gpg: Signature made Tue Aug 01 22:21:11 2017 UTC
gpg:                using RSA key DBEF89774DDB9EB37D9FC3A03CFCF9BAF27EAB47
gpg:                issuer "support@gitlab.com"
gpg: Good signature from "GitLab, Inc. <support@gitlab.com>" [unknown]
Primary key fingerprint: DBEF 8977 4DDB 9EB3 7D9F  C3A0 3CFC F9BA F27E AB47
```

##### Configuring debsigs

Configuring a policy and keyring for `debsigs` can be complicated, so GitLab provides `gitlab-debsigs.sh` as a scripted method of configuration.

To use this script, you will need to download the public key and the script.

```shell
curl -JLO  https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
curl -JLO https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/scripts/gitlab-debsigs.sh
chmod +x gitlab-debsigs.sh
sudo ./gitlab-debsigs.sh gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
```

##### Verify with `debsig-verify`

To make use of `debsig-verify`, perform the steps in [Configuring debsigs](#configuring-debsigs) and install the `debsig-verify` package.

`debsig-verify gitlab-xxx.deb`
