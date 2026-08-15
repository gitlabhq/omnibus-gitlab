---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Regenerate a version manifest for a tag
---

Each release publishes a `version-manifest.json` file that records the exact version of every
bundled component. The `manifest-upload` CI job builds and uploads this file to the manifests S3
bucket, where it is served on the
[manifests page](https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab-manifests/manifests.html).

Use `support/regenerate-manifest.rb` to rebuild and upload the manifest for a single release tag.
Use it to backfill the manifest when the `manifest-upload` job fails for a release.

## Prerequisites

- Docker, with permission to pull the Omnibus builder image.
- Network access to `gitlab.com` and to the S3 bucket.
- The manifest bucket credentials, available as protected CI/CD variables on the
  [Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab) project:
  - `LICENSE_S3_BUCKET`
  - `LICENSE_AWS_ACCESS_KEY_ID`
  - `LICENSE_AWS_SECRET_ACCESS_KEY`

## Regenerate the manifest

Run the script inside the builder image, passing the release tag:

```shell
docker run -it --rm \
  -e LICENSE_S3_BUCKET=<your_bucket> \
  -e LICENSE_AWS_ACCESS_KEY_ID=<key> \
  -e LICENSE_AWS_SECRET_ACCESS_KEY=<secret> \
  -v "$PWD/support/regenerate-manifest.rb:/regenerate-manifest.rb" \
  registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/ubuntu_22.04:5.60.2 \
  ruby /regenerate-manifest.rb 19.0.5+ee.0
```

The script:

- Derives the edition (CE or EE) from the tag. To override, pass `--edition ce` or `--edition ee`.
- Clones and checks out the tag in an isolated working directory.
- Runs `bundle install`, then `rake manifest:upload`.

The script checks the exit code of every step. A failure stops the run instead of continuing
silently.

To authenticate clones to `gitlab.com` with a higher rate limit, set `GITLAB_TOKEN` to a personal
access token with the `read_api` scope. When set, the script configures Git proactive
authentication for `gitlab.com`. The token is read at authentication time and is not written to
disk.

In CI, when `GITLAB_TOKEN` is not set, the script uses `CI_JOB_TOKEN` to authenticate the
`omnibus-gitlab` clone, but only when the pipeline runs on `gitlab.com`. A job token is scoped to
both the host that issued it and the project it belongs to. On other hosts, such as
`dev.gitlab.org`, sending the token to `gitlab.com` fails authentication, so the script clones
anonymously instead.

With a job token, the component version lookups run anonymously. They target public repositories
such as `gitlab-org/gitlab`, and the `omnibus-gitlab` job token is not necessarily authorized for
those projects. This avoids the earlier failure, where proactive authentication forced a
`dev.gitlab.org` job token onto `git ls-remote https://gitlab.com/gitlab-org/gitlab`.

## Overwrite protection

By default, the script refuses to replace a manifest that already exists in the bucket. It sets
`MANIFEST_OVERWRITE=false`, which makes `rake manifest:upload` fail before uploading if the target
object is present.

To replace an existing manifest, pass `--overwrite` (or set `OVERWRITE=true`):

```shell
ruby /regenerate-manifest.rb --overwrite 19.0.5+ee.0
```

The default `manifest-upload` release job does not set `MANIFEST_OVERWRITE`, so its behavior is
unchanged: it always uploads.

## Uploaded object

The manifest is uploaded to the following key. The version component includes the tag build
iteration, matching what the release job publishes:

```plaintext
gitlab-manifests/gitlab-<edition>/<major.minor>/<version>-<build-iteration>-<edition>.version-manifest.json
```

For example, tag `19.0.5+ee.0` produces:

```plaintext
gitlab-manifests/gitlab-ee/19.0/19.0.5-ee.0-ee.version-manifest.json
```

The script prints the expected object key and a verification command when it finishes:

```shell
aws s3 ls s3://<your_bucket>/gitlab-manifests/gitlab-ee/19.0/19.0.5-ee.0-ee.version-manifest.json
```

The `rake manifest:upload` task uploads to the `eu-west-1` region by default. To test against a
bucket in another region, set `LICENSE_S3_BUCKET_REGION`.

> [!warning]
> The manifest bucket is shared across all releases. Confirm `LICENSE_S3_BUCKET` points to the
> intended bucket before you run the script, and keep the overwrite protection enabled unless you
> intend to replace a published manifest.
