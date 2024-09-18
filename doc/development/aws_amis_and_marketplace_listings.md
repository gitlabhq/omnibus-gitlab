---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Amazon Machine Images (AMIs) and Marketplace Listings

GitLab caters to the AWS ecosystem via the following methods

1. Community AMIs
   1. [GitLab CE](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20CE;sort=desc:name) - amd64 and arm64
   1. [GitLab EE](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20EE;sort=desc:name) (Unlicensed) - amd64 and arm64

1. [AWS Marketplace listing](https://aws.amazon.com/marketplace/seller-profile?id=9657c703-ca56-4b54-b029-9ded0fadd970)
   1. [GitLab Premium Self-Managed and Duo Pro (license)](https://aws.amazon.com/marketplace/pp/prodview-vehcu2drxakic) 
   1. [GitLab Ultimate Self-Managed and Duo Pro (license)](https://aws.amazon.com/marketplace/pp/prodview-si5mlpxc22ni2)

## Building the AMIs

AMIs are built as part of regular release process in the tag pipelines that run
in the [Build mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab), and use the
Ubuntu 22.04 packages under the hood. They are built using [`packer`](https://www.packer.io/)
with their [`Amazon EBS`](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs)
builder. Each Community AMI listed above has a corresponding packer
configuration file to specify the build and AMI attributes and an update script
to install the GitLab package and configure the AMI's startup behaviors. The
update script downloads the Ubuntu 22.04 package and installs it on the VM. It
also installs a [`cloud-init`](https://docs.aws.amazon.com/linux/al2/ug/what-is-amazon-linux.html#amazon-linux-cloud-init)
script which automatically configures (with a `gitlab-ctl reconfigure` run) the
GitLab instance to work with the VM's external IP address on startup.

In addition to these public Community AMIs, two private AMIs are also built -
for GitLab EE Premium and Ultimate tiers, which ships 5-seat licenses of the
respective GitLab tier. This license file gets used as part of the initial
`gitlab-ctl reconfigure` run on VM startup. These AMIs are backing our AWS
Marketplace listings.

## Releasing to AWS Marketplace

In addition to building the AMIs during the release process, Omnibus GitLab
tag pipeline also publishes the new version of the respective AWS Marketplace
listing. The private AMIs mentioned above are used to back these listings. As
part of release pipeline, we submit a changeset to publish the new version.
Unlike AMI creation, this process is not immediate and we need to manually check
the status of the changeset periodically to ensure it got applied to the
listings, preferably after 24 hours.

## Common release blocker events

The following events has happen often in the past, and has caused the release
pipeline to fail, and needs immediate attention:

1. Exhausting quota on Public AMIs - When builds fail due to quota exhaustion,
   as an immediate fix, request a quota increase. Then discuss with
   Alliances/Product on de-registering or making private AMIs of some of the
   older versions.
   Also check [issue discussing retention policy of AMIs](https://gitlab.com/gitlab-org/distribution/team-tasks/-/issues/1149).

1. AWS Marketplace version limit - AWS Marketplace has a 100 versions limit for
   each product, exhausting which we can't publish newer versions. However, they
   usually inform us (via email to a specific email account which is forwarded
   to selected Distribution Build team and Alliance team members) which is when
   we are nearing that limit, and we work with Alliances/Product to unlist some
   of the older versions.

1. AWS Marketplace listing blocked by a pending changeset - When this happens,
   the changeset needs to be manually cancelled, and the Marketplace release job
   in the release pipeline needs to be retried. This requires someone with
   Maintainer level access to the Build mirror of `omnibus-gitlab` project.
