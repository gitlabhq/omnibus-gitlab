---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linux package signatures
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

We use a [packagecloud](https://packagecloud.io) instance at <https://packages.gitlab.com> to share the
different OS packages we offer.

The instance uses various cryptographic methods to ensure the integrity of these packages.

## Package repository metadata signing keys

The APT and YUM repositories on the packagecloud instance use a GPG key to
sign their metadata. This key is automatically installed by the repository setup
script specified in the installation instructions.

### Current signing key

| Key attribute | Value |
|:--------------|:------|
| Name          | `GitLab B.V.` |
| EMail         | `packages@gitlab.com` |
| Comment       | `package repository signing key` |
| Fingerprint   | `F640 3F65 44A3 8863 DAA0 B6E0 3F01 618A 5131 2F3F` |
| Expiry        | `2026-02-27` |

This key is active from **2020-04-06**.

The key's expiry was extended from **2024-03-01** to **2026-02-27**. If you encounter an expiration of `2024-03-01`,
follow the instructions below.

{{< tabs >}}

{{< tab title="Debian-based distributions" >}}

packagecloud made used `apt-key`, which [is deprecated](https://blog.packagecloud.io/secure-solutions-for-apt-key-add-deprecated-messages/)
. Manually installed or configured repositories from some distributions, such as [TurnKey Linux](https://www.turnkeylinux.org/),
are already using the `signed-by` support in Debian package source lists.

1. Determine if you're using `apt-key` or `signed-by`:

   ```shell
   grep 'deb \[signed-by=' /etc/apt/sources.list.d/gitlab_gitlab-?e.list
   ```

   If this command:

   - Returns any lines, you're using `signed-by`, which takes precedence over `apt-key`.
   - No lines, you're using `apt-key`.

1. If using `signed-by`, run this script as root to update the public keys for GitLab repositories:

   ```shell
   awk '/deb \[signed-by=/{
         pubkey = $2;
         sub(/\[signed-by=/, "", pubkey);
         sub(/\]$/, "", pubkey);
         print pubkey
       }' /etc/apt/sources.list.d/gitlab_gitlab-?e.list | \
     while read line; do
       curl -s "https://packages.gitlab.com/gpg.key" | gpg --dearmor > $line
     done
   ```

1. If using `apt-key`, run this script as root to update the public keys for GitLab repositories:

   ```shell
   apt-key del 3F01618A51312F3F
   curl -s "https://packages.gitlab.com/gpg.key" | apt-key add -
   apt-key list 3F01618A51312F3F
   ```

{{< /tab >}}

{{< tab title="RPM-based distributions" >}}

YUM and DNF have small differences, but the underlying configuration is identical:

1. Remove any existing key from the repository keyrings:

   ```shell
   for pubring in /var/cache/dnf/*gitlab*/pubring
   do
     gpg --homedir $pubring --delete-key F6403F6544A38863DAA0B6E03F01618A51312F3F
   done
   ```

1. Update the repository data and cache, which asks you to confirm keys:

   ```shell
   dnf check-update
   ```

{{< /tab >}}

{{< /tabs >}}

### Fetch latest signing key

To fetch the latest repository signing key:

1. Download the key:

   ```shell
   curl "https://packages.gitlab.com/gpg.key" -o /tmp/omnibus_gitlab_gpg.key
   ```

1. Import the key:

   {{< tabs >}}

   {{< tab title="Debian/Ubuntu/Raspbian" >}}

   ```shell
   sudo apt-key add /tmp/omnibus_gitlab_gpg.key
   ```

   {{< /tab >}}

   {{< tab title="CentOS/OpenSUSE/SLES" >}}

   ```shell
   sudo rpm --import /tmp/omnibus_gitlab_gpg.key
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. Make sure that the new key has the necessary permissions to be properly recognized by your OS, which should be `644`.
   You can set the permissions by running:

   ```shell
   chmod 644 <keyfile>
   ```

### Previous key

| Sl. No. | Key ID                                               | Expiry date |
|:--------|:-----------------------------------------------------|:------------|
| 1       | `1A4C 919D B987 D435 9396  38B9 1421 9A96 E15E 78F4` | `2020-04-15` |

## Package signatures

This section provides methods for verifying the signatures of GitLab-produced packages, both manually and automatically
where supported.

### Details of current package signing key

| Key attribute | Value |
|---------------|-------|
| Name          | `GitLab, Inc.` |
| EMail         | `support@gitlab.com` |
| Fingerprint   | `98BF DB87 FCF1 0076 416C 1E0B AD99 7ACC 82DD 593D` |
| Expiry        | `2026-02-14` |

#### Older package signing keys

| Sl. No. | Key ID                                              | Revocation date | Expiry date  | Download location |
|---------|-----------------------------------------------------|-----------------|--------------|-------------------|
| 1       | `9E71 648F 3A35 EA00 CAE4 43E7 1155 1132 6BA7 34DA` | `2025-02-14`    | `2025-07-01` | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-3D645A26AB9FBD22.pub.gpg` |

### RPM-based distributions

The RPM format contains a full implementation of GPG signing functionality and is fully integrated with the package
management systems based upon that format.

#### Verify GitLab public key is present

To verify a package on an RPM based distribution, ensure that the GitLab, Inc. public key is present in the `rpm`
keychain. For example:

```shell
rpm -q gpg-pubkey-82dd593d-67aefdd8 --qf '%{name}-%{version}-%{release} --> %{summary}'
```

This command produces either:

- Information on the public key.
- A message that the key isn't installed. For example: `gpg-pubkey-f27eab47-60d4a67e is not installed`.

If the key is not present, import it. For example:

```shell
rpm --import https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
```

#### Verify if signature check is active

To check if package signature checking is active on an existing install, compare the content of the repository file:

1. Check if the repository file exist: `file /etc/yum.repos.d/gitlab_gitlab-ce.repo`.
1. Check that signature checking is active: `grep gpgcheck /etc/yum.repos.d/gitlab_gitlab-ce.repo`. This command should
   output:

   ```plaintext
   repo_gpgcheck=1
   gpgcheck=1
    ```

   or

   ```plaintext
   repo_gpgcheck=1
   pkg_gpgcheck=1
   ```

If the file does not exist, you don't have the repository installed. If the file exists, but the output shows
`gpgpcheck=0`, then you must edit that value to enable it.

#### Verify a Linux package `rpm` file

After confirming that the public key is present, verify the package:

```shell
rpm --checksig gitlab-xxx.rpm
```

### Debian-based distributions

The Debian package format does not officially contain a method for signing packages. We implemented the `debsig`
standard, which is well documented but not enabled by default on most distributions.

You can verify Linux package `deb` file by either:

- Using `debsig-verify` after configuring the necessary `debsigs` policy and keyring.
- Manually checking the contained `_gpgorigin` file with GnuPG.

#### Configure `debsigs`

Because configuring a policy and keyring for `debsigs` can be complicated, we provide the `gitlab-debsigs.sh` script
for configuration. To use this script, you need to download the public key and the script.

```shell
curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
curl -JLO "https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/scripts/gitlab-debsigs.sh"
chmod +x gitlab-debsigs.sh
sudo ./gitlab-debsigs.sh gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
```

#### Verify with `debsig-verify`

To use of `debsig-verify`:

1. [Configure `debsigs`](#configure-debsigs).
1. Install the `debsig-verify` package.
1. Run `debsig-verify` to verify the file:

   ```shell
   debsig-verify gitlab-xxx.deb
   ```

#### Verify with GnuPG

If you don't want to install dependencies installed by `debsig-verify`, you can use GnuPG instead:

1. Download and import the package signing public key:

   ```shell
   curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
   gpg --import gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
   ```

1. Extract the signature file `_gpgorigin`:

   ```shell
   ar x gitlab-xxx.deb _gpgorigin
   ```

1. Verify the signature matches the content:

   ```shell
   ar p gitlab-xxx.deb debian-binary control.tar.xz data.tar.xz | gpg --verify _gpgorigin -
   ```

   The output of this command should appear like this:

   ```shell
   gpg: Signature made Tue Aug 01 22:21:11 2017 UTC
   gpg:                using RSA key DBEF89774DDB9EB37D9FC3A03CFCF9BAF27EAB47
   gpg:                issuer "support@gitlab.com"
   gpg: Good signature from "GitLab, Inc. <support@gitlab.com>" [unknown]
   Primary key fingerprint: DBEF 8977 4DDB 9EB3 7D9F  C3A0 3CFC F9BA F27E AB47
   ```

If the verification fails with `gpg: BAD signature from "GitLab, Inc. <support@gitlab.com>" [unknown]`, ensure:

- The file names are written in correct order.
- The file names match the content of the archive.

Depending on what Linux distribution you use, the content of the archive might have a different suffix. This means you
need to adjust the command accordingly. To confirm the content of the archive, run `ar t gitlab-xxx.deb`.

For example, for Ubuntu Focal (20.04):

```shell
$ ar t gitlab-ee_17.4.2-ee.0_amd64.deb
debian-binary
control.tar.xz
data.tar.xz
_gpgorigin
```
