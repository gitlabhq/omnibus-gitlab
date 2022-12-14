---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI Variables

`omnibus-gitlab` [CI pipelines](pipelines.md) use variables provided by the CI environment to change build behavior between mirrors and
keep sensitive data out of the repositories.

Check the table below for more information about the various CI variables used in the pipelines.

## Build variables

**Required:**

These variables are required to build packages in the pipeline.

| Environment Variable                          | Description |
| --------------------------------------------- | ----------- |
| AWS_SECRET_ACCESS_KEY                         | Account secret to read/write the build package to a S3 location. |
| AWS_ACCESS_KEY_ID                             | Account ID to read/write the build package to a S3 location. |

**Available:**

These additional variables are available to override or enable different build behavior.

| Environment Variable                          | Description |
| --------------------------------------------- | ----------- |
| AWS_MAX_ATTEMPTS                              | Maximum number of times an S3 command should retry. |
| USE_S3_CACHE                                  | Set to any value and Omnibus will cache fetched software sources in an s3 bucket. [Upstream documentation](https://www.rubydoc.info/github/chef/omnibus/Omnibus%2FConfig:use_s3_caching). |
| CACHE_AWS_ACCESS_KEY_ID                       | Account ID to read/write from the s3 bucket containing the s3 software fetch cache. |
| CACHE_AWS_SECRET_ACCESS_KEY                   | Account secret to read/write from the s3 bucket containing the s3 software fetch cache. |
| CACHE_AWS_BUCKET                              | S3 bucket name for the software fetch cache. |
| CACHE_AWS_S3_REGION                           | S3 bucket region to write/read the software fetch cache. |
| CACHE_AWS_S3_ENDPOINT                         | The HTTP or HTTPS endpoint to send requests to, when using s3 compatible service. |
| CACHE_S3_ACCELERATE                           | Setting any value enables the s3 software fetch cache to pull using s3 accelerate. |
| SECRET_AWS_SECRET_ACCESS_KEY                  | Account secret to read the gpg private package signing key from a secure s3 bucket. |
| SECRET_AWS_ACCESS_KEY_ID                      | Account ID to read the gpg private package signing key from a secure s3 bucket. |
| GPG_PASSPHRASE                                | The passphrase needed to use the gpg private package signing key.        |
| CE_MAX_PACKAGE_SIZE_MB                        | The max package size in MB allowed for CE packages before we alert the team and investigate. |
| EE_MAX_PACKAGE_SIZE_MB                        | The max package size in MB allowed for EE packages before we alert the team and investigate. |
| DEV_GITLAB_SSH_KEY                            | SSH private key for an account able to read repositories from `dev.gitlab.org`. Used for SSH Git fetch. |
| BUILDER_IMAGE_REGISTRY                        | Registry to pull the CI Job images from. |
| BUILD_LOG_LEVEL                               | Omnibus build log level. |
| ALTERNATIVE_SOURCES                           | Switch to the custom sources listed in `https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml` Defaults to `true`. |
| OMNIBUS_GEM_SOURCE                            | Non-default remote URI to clone the omnibus gem from. |
| QA_BUILD_TARGET                               | Build specified QA image. See this [MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91250) for details. Defaults to `qa`. |
| GITLAB_ASSETS_TAG                             | Tag of the assets image built by the `build-assets-image` job in the `gitlab-org/gitlab` pipelines. Defaults to `$GITLAB_REF_SLUG` or the `gitlab-rails` version. |

## Test variables

| Environment Variable                                         | Description                                                                         |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| RAT_REFERENCE_ARCHITECTURE                                   | Reference architecture template used in pipeline triggered by RAT job.              |
| RAT_FIPS_REFERENCE_ARCHITECTURE                              | Reference architecture template used in pipeline triggered by RAT:FIPS job.         |
| RAT_PACKAGE_URL                                              | URL to fetch regular package - for RAT pipeline triggered by RAT job.               |
| RAT_FIPS_PACKAGE_URL                                         | URL to fetch FIPS package - for RAT pipeline triggered by RAT job.                  |
| RAT_TRIGGER_TOKEN                                            | Trigger token for the RAT pipeline.                                                 |
| RAT_PROJECT_ACCESS_TOKEN                                     | Project access token for trigerring a RAT pipeline.                                 |
| OMNIBUS_GITLAB_MIRROR_PROJECT_ACCESS_TOKEN                   | Project access token for building a test package.                                   |
| GITLAB_QA_MIRROR_PROJECT_ACCESS_TOKEN                        | Project access token for triggering a downstream pipeline for end-to-end testing.   |
| GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN (deprecated) | Trigger token for building a test package.                                          |
| CI_SLACK_WEBHOOK_URL                                         | Webhook URL for Slack failure notifications.                                        |
| DANGER_GITLAB_API_TOKEN                                      | GitLab API token for dangerbot to post comments to MRs.                             |
| DEPS_GITLAB_TOKEN                                            | Token used by [dependencies.io](https://www.dependencies.io/gitlab/) to create MRs. |
| DEPS_TOKEN                                                   | Token used by CI to auth to [dependencies.io](https://www.dependencies.io/gitlab/). |
| DOCS_API_TOKEN

## Release variables

**Required:**

These variables are required to release packages built by the pipeline.

| Environment Variable                          | Description |
| --------------------------------------------- | ----------- |
| STAGING_REPO                                  | Repository at `packages.gitlab.com` where releases are uploaded prior to final release. |
| PACKAGECLOUD_USER                             | Packagecloud username for pushing packages to `packages.gitlab.com`. |
| PACKAGECLOUD_TOKEN                            | API access token for pushing packages to `packages.gitlab.com`. |
| LICENSE_S3_BUCKET                             | Bucket for storing release license information published on the public page at `https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html`. |
| LICENSE_AWS_SECRET_ACCESS_KEY                 | Account secret to read/write from the S3 bucket containing license information. |
| LICENSE_AWS_ACCESS_KEY_ID                     | Account ID to read/write from the S3 bucket containing license information. |
| GCP_SERVICE_ACCOUNT                           | Used to read/write metrics in Google Object Storage. |
| DOCKERHUB_USERNAME                            | Username used when pushing the Omnibus GitLab image to Docker Hub. |
| DOCKERHUB_PASSWORD                            | Password used when pushing the Omnibus GitLab image to Docker Hub. |
| AWS_ULTIMATE_LICENSE_FILE                     | GitLab Ultimate license to use the Ultimate AWS AMIs. |
| AWS_PREMIUM_LICENSE_FILE                      | GitLab Premium license to use the Ultimate AWS AMIs. |
| AWS_AMI_SECRET_ACCESS_KEY                     | Account secret for read/write access to publish the AWS AMIs. |
| AWS_AMI_ACCESS_KEY_ID                         | Account ID for read/write access to publish the AWS AMIs. |
| AWS_MARKETPLACE_ARN                           | AWS ARN to allow AWS Marketplace access our official AMIs. |

**Available:**

These additional variables are available to override or enable different build behavior.

| Environment Variable                          | Description |
| --------------------------------------------- | ----------- |
| RELEASE_DEPLOY_ENVIRONMENT                    | Deployment name used for [`gitlab.com` deployer](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) trigger if current ref is a stable tag. |
| PATCH_DEPLOY_ENVIRONMENT                      | Deployment name used for the [`gitlab.com` deployer](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) trigger if current ref is a release candidate tag. |
| AUTO_DEPLOY_ENVIRONMENT                       | Deployment name used for the [`gitlab.com` deployer](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) trigger if current ref is an auto-deploy tag. |
| DEPLOYER_TRIGGER_PROJECT                      | GitLab project ID for the repository used for the [`gitlab.com` deployer](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md). |
| DEPLOYER_TRIGGER_TOKEN                        | Trigger token for the various [`gitlab.com` deployer](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md) environments. |
| RELEASE_BUCKET                                | S3 bucket where release packages are pushed. |
| BUILDS_BUCKET                                 | S3 bucket where regular branch packages are pushed. |
| RELEASE_BUCKET_REGION                         | S3 bucket region. |
| RELEASE_BUCKET_S3_ENDPOINT                    | Specify S3 endpoint. Especially useful when S3 compatible storage service is adopted. |
| GITLAB_BUNDLE_GEMFILE                         | Set Gemfile path required by `gitlab-rails` bundle. Default is `Gemfile`. |
| GITLAB_COM_PKGS_BUCKET                        | GCS bucket where release packages are pushed for SaaS deployments. |
| GITLAB_COM_PKGS_SA_FILE                       | Service account key used for pushing release packages for SaaS deployments, it must have write access to the pkgs bucket. |

## Unknown/outdated variables

| Environment Variable                          | Description |
| --------------------------------------------- | ----------- |
| VERSION_TOKEN                                 | |
| TAKEOFF_TRIGGER_TOKEN                         | |
| TAKEOFF_TRIGGER_PROJECT                       | |
| RELEASE_TRIGGER_TOKEN                         | |
| GITLAB_DEV                                    | |
| GET_SOURCES_ATTEMPTS                          | A GitLab Runner variable used to control how many times runner tries to fetch the Git repository. |
| FOG_REGION                                    | |
| FOG_PROVIDER                                  | |
| FOG_DIRECTORY                                 | |
| AWS_RELEASE_TRIGGER_TOKEN                     | Used for releases older than 13.10. |
| ASSETS_AWS_SECRET_ACCESS_KEY                  | |
| ASSETS_AWS_ACCESS_KEY_ID                      | |
| AMI_LICENSE_FILE                              | |
