# aws_access_key is the AWS PAT public key.
variable "aws_access_key" {
  type = string
}

# aws_access_key is the AWS PAT private key.
variable "aws_secret_key" {
  type = string
}

# download_url is the URL used to download the Ubuntu Focal GitLab Omnibus
# debian package.
variable "download_url" {
  type = string
}

# ci_job_token is the token used to download the package from CI artifacts
variable "ci_job_token" {
  type = string
}

# license_file, somewhat of a misnomer, is the contents of the license to
# install on the image. Due to the size of the license contents, it is usually
# better to use a shell variable to hold the contents and then use the variable
# reference on the command line, e.g.,
#
# GITLAB_LICENSE="eyJkYXRhIjoicEoy..."
# packer build ... -var "license_file=$GITLAB_LICENSE" ...
#
# Note: Licenses are not needed for the Community Edition. Leave this variable
# set to the default.
variable "license_file" {
  type    = string
  default = ""
}

# version is the version to use in the image name, description, and tag. It does
# not affect the installed version which is determined by the downloaded GitLab
# Omnibus deb).
variable "version" {
  type    = string
  default = "99.99.99"
}

# ami_regions are a list of regions to copy the resulting AMI to (copied from
# the 'us-east-1' region). For local develoment builds use -var "ami_regions=[]"
# so no copying is done.
variable "ami_regions" {
  type = list(string)
  default = [
    "af-south-1",
    "ap-northeast-1",
    "ap-northeast-2",
    "ap-northeast-3",
    "ap-south-1",
    "ap-southeast-1",
    "ap-southeast-2",
    "ca-central-1",
    "eu-central-1",
    "eu-north-1",
    "eu-south-1",
    "eu-west-1",
    "eu-west-2",
    "eu-west-3",
    "me-south-1",
    "sa-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
  ]
}

# ami_prefix is used to preface the the AMI description and name with something
# useful to differentiate a local development build image from a production
# build. Set it to something useful when doing local build testing. Example:
#
#    -var "ami_prefix=Sally G Test".
#
# would create an image with the AMI name and description of "Sally G Test
# <version> ...".
variable "ami_prefix" {
  type    = string
  default = ""
}

data "amazon-ami" "base_ami" {
  access_key = "${var.aws_access_key}"
  filters = {
    name                = "ubuntu/images/*ubuntu-focal-20.04-arm64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "us-east-1"
  secret_key  = "${var.aws_secret_key}"
}

source "amazon-ebs" "base_ami" {
  access_key      = "${var.aws_access_key}"
  ami_description = "${var.ami_prefix}GitLab CE ${var.version} (ARM64) AMI. https://about.gitlab.com/"
  ami_name        = "${var.ami_prefix}GitLab CE ${var.version} (ARM64)"
  ami_groups      = ["all"]
  ami_users       = ["684062674729", "679593333241"]
  ena_support     = true
  instance_type   = "m6g.medium"
  region          = "us-east-1"
  secret_key      = "${var.aws_secret_key}"
  snapshot_users  = ["684062674729", "679593333241"]
  source_ami      = "${data.amazon-ami.base_ami.id}"
  sriov_support   = true
  ssh_username    = "ubuntu"
  tags = {
    Type    = "GitLab Community Edition (ARM64)"
    Version = "${var.version}"
  }
  ami_regions = "${var.ami_regions}"
}

build {
  sources = ["source.amazon-ebs.base_ami"]

  provisioner "file" {
    destination = "/home/ubuntu/ami-startup-script.sh"
    source      = "./ami-startup-script.sh"
  }

  provisioner "shell" {
    environment_vars = ["DOWNLOAD_URL=${var.download_url}", "CI_JOB_TOKEN=${var.ci_job_token}"]
    script           = "update-script-ce.sh"
  }

  post-processor "manifest" {
    output = "manifests/ce-arm64-manifest.json"
    custom_data = {
      name: "${var.ami_prefix}GitLab CE ${var.version} (ARM64)"
    }
  }
}
