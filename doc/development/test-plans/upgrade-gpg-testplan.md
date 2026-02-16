---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `GnuPG` related component upgrade (gnupg, gpgme, libassuan, libgcrypt, libgpg-error, libksba, npth)
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Performed a successful GitLab Enterprise Edition (EE) build on all supported platforms (include `build-package-on-all-os` job).
- [ ] Installed and started GitLab in a VM or container with a package you built in the previous task.
- [ ] Created a GPG key.
  1. Sign in to GitLab.
  1. Create a new project, clone it locally .
  1. Go to "Edit Profile > Emails" and copy the verified linked email. Export it as an environment variable:

     ```shell
     export GITLAB_EMAIL="ADD_EMAIL_HERE"
     ```

  1. Generate a GPG key pair. Sample on how to do it from the GPG docs below.

     ```shell
     export GNUPGHOME="$(mktemp -d)"
       cat >foo <<EOF
         %echo Generating a basic OpenPGP key
         Key-Type: DSA
         Key-Length: 1024
         Subkey-Type: ELG-E
         Subkey-Length: 1024
         Name-Real: GPG Tester
         Name-Comment: some comment
         Name-Email: $GITLAB_EMAIL
         Expire-Date: 1
         Passphrase: abc
         # Do a commit here, so that we can later print "done" :-)
         %commit
         %echo done
       EOF
     gpg --batch --generate-key foo
     gpg --list-signatures --keyid-format LONG | grep pub
     gpg --armor --export "$GITLAB_EMAIL"
     ```

- [ ] Configured the GPG key.
  - Edit your profile and add the gpg key listed.
  - After importing your gpg key copy its ID from the profile page. It is the first string shown. Its short version is also visible as the output from the gpg --list-signatures command above.

    ```shell
    export GPG_KEY_ID="CHANGE_THIS_KEY_ID"
    ```

  - Locally, in the cloned repo configure git to use your key and email

    ```shell
    git config --local user.signingkey "$GPG_KEY_ID"
    git config --local user.email "$GITLAB_EMAIL"
    ```

- [ ] Verified the GPG key works correctly.
  - Add some content to your repo, add it to the index and then commit, sign, and push:

    ```shell
    git commit -S -m "Test commit to verify signatures"
    git push
    ```

  - In the repository history on GitLab, verify the commit is marked as `verified`.
````
