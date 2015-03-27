# Preparing a build environment

See
https://gitlab.com/gitlab-org/gitlab-omnibus-builder/blob/master/README.md#recipe-default
for instructions on how to prepare a build box using Chef. After running the cookbook you can perform builds as the `omnibus-build` user.

```shell
# Login as omnibus-build user
sudo su - omnibus-build

# Clone the omnibus repo
git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git

# Install gem dependencies for omnibus-ruby
cd omnibus-gitlab
bundle install --path .bundle --binstubs

# Do a build
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
