---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `pgbouncer` component changes
---

Copy the following test plan to a comment of the merge request that changes the `pgbouncer` component.

````markdown
## Test plan

### Setup

Obtain the Docker image tag from the EE pipeline triggered in the MR. Look for the
`Docker-branch` job in the `image` stage of the downstream `trigger-ee-package` pipeline
and find the image tag logged in the job output, for example:

```plaintext
Running command: "docker buildx imagetools create -t registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ee:<TAG> ..."
```

Then set the tag as an environment variable and pull the image:

```shell
export TEST_TAG="<image-tag-from-pipeline>"
export GITLAB_IMAGE="registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ee:${TEST_TAG}"

docker pull "${GITLAB_IMAGE}"
```

### Checklist

- [ ] Performed a successful GitLab Enterprise Edition (EE) build on all supported platforms
  (include `build-package-on-all-os` job).
- [ ] Ran `qa-subset-test` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Verified the binary exists at the correct path and reports the expected version:

  ```shell
  docker run --rm "${GITLAB_IMAGE}" /opt/gitlab/embedded/bin/pgbouncer --version
  ```

  Expected output:

  ```plaintext
  PgBouncer <expected-version>
  ```

- [ ] Verified the binary is dynamically linked against embedded libraries (not system ones):

  ```shell
  docker run --rm "${GITLAB_IMAGE}" ldd /opt/gitlab/embedded/bin/pgbouncer
  ```

  Expected: all shared libraries (`libevent`, `libssl`, `libcrypto`) resolve to paths under
  `/opt/gitlab/embedded/`. No unresolved symbols.

- [ ] Verified the service starts correctly on a pgbouncer node.

  First, compute the password hash from the concatenated password and username:

  ```shell
export RAW_MD5=$(printf '%s' "<plaintext-password>pgbouncer" | md5sum | awk '{print $1}')
  ```

  Then start the container:

  ```shell
  docker run -d \
    --name gitlab-pgbouncer-test \
    -p 6432:6432 \
    -e GITLAB_OMNIBUS_CONFIG="
      roles ['pgbouncer_role']
      pgbouncer['admin_users'] = %w(pgbouncer)
      pgbouncer['users'] = {
        'pgbouncer' => {
          'password' => '${RAW_MD5}',
        }
      }
    " \
    "${GITLAB_IMAGE}"
  ```

  After ~60 seconds, check the service status:

  ```shell
  docker exec gitlab-pgbouncer-test gitlab-ctl status pgbouncer
  ```

  Expected: `run: pgbouncer: (pid XXXX) Xs; run: log/pgbouncer: ...`

- [ ] Verified the pgbouncer admin console accepts connections and responds to commands:

  ```shell
  docker exec gitlab-pgbouncer-test \
    bash -c 'PGPASSWORD="<plaintext-password>" /opt/gitlab/embedded/bin/psql \
    -h /var/opt/gitlab/pgbouncer \
    -p 6432 \
    -U pgbouncer \
    -d pgbouncer \
    -c "SHOW VERSION;"'
  ```

  Expected output:

  ```plaintext
   version
  ------------------
   PgBouncer <expected-version>
  (1 row)
  ```

  Also verify stats are accessible:

  ```shell
  docker exec gitlab-pgbouncer-test \
    bash -c 'PGPASSWORD="<plaintext-password>" /opt/gitlab/embedded/bin/psql \
    -h /var/opt/gitlab/pgbouncer \
    -p 6432 \
    -U pgbouncer \
    -d pgbouncer \
    -c "SHOW STATS;"'
  ```

  Expected: a table of stats with no errors.

- [ ] Verified the service stop/start lifecycle works correctly:

  ```shell
  # Stop the service
  docker exec gitlab-pgbouncer-test gitlab-ctl stop pgbouncer

  # Confirm it stopped
  docker exec gitlab-pgbouncer-test gitlab-ctl status pgbouncer
  # Expected: "down: pgbouncer: ..."

  # Start the service again
  docker exec gitlab-pgbouncer-test gitlab-ctl start pgbouncer

  # Confirm it is back up
  docker exec gitlab-pgbouncer-test gitlab-ctl status pgbouncer
  # Expected: "run: pgbouncer: ..."
  ```


### Cleanup

```shell
docker stop gitlab-pgbouncer-test
docker rm gitlab-pgbouncer-test
```
````
