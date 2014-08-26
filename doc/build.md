# Preparing a build environment

To create builds you will need a build user (`omnibus-build:omnibus-build` in our example).
Preparing the build machine requires sudo access.

## Ubuntu 12.04, 14.04

```shell
# Get the latest OS updates
sudo apt-get update
sudo apt-get upgrade

# Set up the firewall to only allow inbound SSH traffic
sudo apt-get install ufw
sudo ufw allow ssh
sudo ufw enable

# Check for SSH password logins, they should be disabled; The command below should return no results
grep '^[^#]*PasswordAuthentication' /etc/ssh/sshd_config

# Install dependencies
sudo apt-get install ruby1.9.1 ruby1.9.1-dev git build-essential cmake
sudo gem install --no-ri --no-rdoc bundler

# Create the build user
sudo adduser --gecos 'Omnibus Build' --disabled-password omnibus-build
# Create build directories for use by the build user
sudo mkdir -p /opt/gitlab /var/cache/omnibus
sudo chown omnibus-build:omnibus-build /opt/gitlab /var/cache/omnibus
```

Then, as the build user (omnibus-build):

```shell
# Login as omnibus-build user
sudo su - omnibus-build

# Clone the omnibus repo
git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git

# Install gem dependencies for omnibus-ruby
cd omnibus-gitlab
bundle install --path .bundle --binstubs

# Do a build (and take a break from the computer)
bin/omnibus build project gitlab
```

## Debian 7.4

the steps to build gitlab with omnibus on Debian 7.4 are equal to the ones to build on Ubuntu 12.04

## Centos 6.5

```shell
# Update OS packages
sudo yum update

# Set up the firewall to only allow inbound SSH traffic
sudo lokkit -s ssh

# Check for SSH password logins; they should be disabled
grep '^[^#]*PasswordAuthentication' /etc/ssh/sshd_config

sudo yum groupinstall 'Development Tools'
# Install RedHat Software Collections to get Ruby 1.9.3
sudo yum install centos-release-SCL
sudo yum install ruby193 ruby193-ruby-devel

# Create the build user
sudo adduser -c 'Omnibus Build' omnibus-build
# Create build directories for use by the build user
sudo mkdir -p /opt/gitlab /var/cache/omnibus
sudo chown omnibus-build:omnibus-build /opt/gitlab /var/cache/omnibus
```

As the build user (omnibus-build):

```shell
# Enable Ruby 1.9.3 from Software Collections
echo 'exec scl enable ruby193 bash' >> .bash_profile
# Start a new login shell so we do not have to log out and in
# this one time
bash --login

# Clone the omnibus repo
git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git

# Install gem dependencies for omnibus-ruby
cd omnibus-gitlab
bundle install --path .bundle --binstubs

# Do a build (and take a break from the computer)
bin/omnibus build project gitlab
```

### Centos 7

As an administrator (or root):

```
yum update

sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --list-all

# Check for SSH password logins; they should be disabled
grep '^[^#]*PasswordAuthentication' /etc/ssh/sshd_config

sudo yum groupinstall 'Development Tools'
sudo yum install ruby ruby-devel cmake
sudo gem install bundler --no-ri --no-rdoc

# Create the build user
sudo adduser -c 'Omnibus Build' omnibus-build
# Create build directories for use by the build user
sudo mkdir -p /opt/gitlab /var/cache/omnibus
sudo chown omnibus-build:omnibus-build /opt/gitlab /var/cache/omnibus
```

As the build user (omnibus-build):

```shell
# Clone the omnibus repo
git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git

# Install gem dependencies for omnibus-ruby
cd omnibus-gitlab
bundle install --path .bundle --binstubs

# Do a build (and take a break from the computer)
bin/omnibus build project gitlab
```

## Usage

### Build

You create a platform-specific package using the `build project` command:

```shell
$ bin/omnibus build project gitlab
```

The platform/architecture type of the package created will match the platform
where the `build project` command is invoked. So running this command on say a
MacBook Pro will generate a Mac OS X specific package. After the build
completes packages will be available in `pkg/`.

### Clean

You can clean up all temporary files generated during the build process with
the `clean` command:

```shell
$ bin/omnibus clean
```

Adding the `--purge` purge option removes __ALL__ files generated during the
build including the project install directory (`/opt/gitlab`) and
the package cache directory (`/var/cache/omnibus/pkg`):

```shell
$ bin/omnibus clean --purge
```

### Help

Full help for the Omnibus command line interface can be accessed with the
`help` command:

```shell
$ bin/omnibus help
```
