---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan fpr Redis component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Performed a successful GitLab Enterprise Edition (EE) build on all supported platforms (include `build-package-on-all-os` job).
- [ ] Ran `qa-subset-test` as well as manual `qa-remaining-test-manual` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Install a custom CA

  - [ ] Generate a custom CA

    ```shell
    $ openssl genrsa -des3 -out customca.key 2048
    $ openssl req -x509 -new -nodes -key customca.key -sha256 -days 365 -out customca.crt
    ```

  - [ ] Copy the custom CA certificate to `/etc/gitlab/trusted-certs/`

    ```shell
    cp customca.pem /etc/gitlab/trusted-certs/
    ```

  - [ ] Reconfigure GitLab and confirm the CA bundle was generated and symlinked

    ```shell
    $ ls -l /etc/gitlab/trusted-certs/
    total 4
    lrwxrwxrwx 1 root root   12 May 12 09:03 9da13359.0 -> customca.crt
    -rw-r--r-- 1 1001 1001 1245 May 12 08:59 customca.crt
    $ ls -l /opt/gitlab/embedded/ssl/certs/
    total 224
    lrwxrwxrwx 1 root root     38 May 12 09:03 9da13359.0 -> /etc/gitlab/trusted-certs/customca.crt
    -rw-r--r-- 1 root root    147 May 12 09:03 README
    -rw-r--r-- 1 root root 224369 Apr 11 13:09 cacert.pem
    ```
````
