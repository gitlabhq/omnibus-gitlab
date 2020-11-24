---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Omnibus GitLab Architecture and Components

Omnibus GitLab is a customized fork of the Omnibus project from Chef, and it
uses Chef components like cookbooks and recipes to perform the task of
configuring GitLab in a user's computer. [Omnibus GitLab repository on GitLab.com](https://gitlab.com/gitlab-org/omnibus-gitlab)
hosts all the necessary components of Omnibus GitLab. These include parts of
Omnibus that is required to build the package, like configurations and project
metadata, and the Chef related components that will be used in a user's computer
after installation.

![Omnibus-GitLab Components](components.png)

An in-depth video walkthrough of these components is available
[on YouTube](https://www.youtube.com/watch?v=m89NHLhTMj4).

## Software Definitions

### GitLab project definition file

A primary component of the omnibus architecture is a project definition file
that lists the project details and dependency relations to external softwares
and libraries.

The main components of this [project definition file](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/config/projects/gitlab.rb)
are:

- Project metadata: Includes attributes such as the project's name and description.
- License details of the project.
- Dependency list: List of external tools and softwares which are required to
  build or run GitLab, and sometimes their metadata.
- Global configuration variables used for installation of GitLab: Includes the
  installation directory, system user, and system group.

### Individual software definitions

Omnibus GitLab follows a batteries-included style of distribution. All of the
software, libraries and binaries necessary for the proper functioning of a
GitLab instance is provided as part of the package, in an embedded format.

So another one of the major components of the omnibus architecture is the
[software definitions and configurations](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config/software).
A typical software configuration consists of the following parts:

- Version of the software required.
- License of the software.
- Dependencies for the software to be built/run.
- Commands needed to build the software and embed it inside the package.

Sometimes, softwares' source code may have to be patched to use it with GitLab.
This may be to fix a security vulnerability, add some functionality needed for
GitLab, or make it work with other component of GitLab. For this purpose,
Omnibus GitLab consists of a [patch directory](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config/patches),
where patches for different software are stored.

For more extensive changes, it may be more convenient to track the required
changes in a branch on the mirror. The pattern to follow for this is to create a
branch from an upstream tag or sha making reference to that branchpoint in the
name of the branch. As an example, from the omnibus codebase, `gitlab-omnibus-v5.6.10`
is based on the `v5.6.10` tag of the upstream project. This allows for us to
generate a comparison link like `https://gitlab.com/gitlab-org/omnibus/compare/v5.6.10...gitlab-omnibus-v5.6.10`
to identify what local changes are present.

## Global GitLab configuration template

Omnibus GitLab ships with it a single configuration file that can be used to
configure each and every part of the GitLab instance, which will be installed to
the user's computer. This configuration file acts as the canonical source of all
configuration settings that will be applied to the GitLab instance. It lists the
general settings for a GitLab instance as well as various options for different
components. The common structure of this file consist of configurations
specified in the format `<component>['<setting>'] = <value>`. All the available
options are listed in the [configuration template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template),
but all except the ones necessary for basic working of GitLab are commented out
by default. Users may uncomment them and specify corresponding values, if
necessary.

## GitLab Cookbook

Omnibus GitLab, as previously described, uses many of the Chef components like
cookbooks, attributes, and resources. GitLab EE uses a separate cookbook that
extends from the one GitLab CE uses and adds the EE-only components. The major
players in the Chef-related part of Omnibus GitLab are the following:

### Default Attributes

[Default attributes](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb),
as the name suggests, specifies the default values to different settings
provided in the configuration file. These values act as fail-safe and get used
if the user doesn't provide a value to a setting, and thus ensure a working
GitLab instance with minimum user tweaking being necessary.

### Recipes

[Recipes](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/recipes)
do most of the heavy-lifting while installing GitLab using omnibus package as
they are responsible for setting up each component of the GitLab ecosystem in a
user's computer. They create necessary files, directories and links in their
corresponding locations, set their permissions and owners, configure, start and
stop necessary services, and notify these services when files corresponding to
them change. A master recipe, named `default`, acts as the entry point and it
invokes all other necessary recipes for various components and services.

### Definitions

[Definitions](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/definitions)
can be considered as global-level macros that are available across recipes. Some
common uses for definitions are defining the ports used for common services, and
listing important directories that may be used by different recipes. They define
resources that may be reused by different recipes.

### Templates for configuration of components

As mentioned earlier, Omnibus GitLab provides a single configuration file to
tweak all components of a GitLab instance. However, architectural design of
different components may require them to have individual configuration files
residing at specific locations. These configuration files have to be generated
from either the values specified by the user in general configuration file or
from the default values specified. Hence, Omnibus GitLab ships with it
[templates of such configuration files](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/templates)
ith placeholders which may be filled by default values or values from user. The
recipes do the job of completing these templates, by filling them and placing
them at necessary locations.

### General library methods

Omnibus GitLab also ships some [library methods](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/libraries)
that primarily does the purpose of code reuse. This include methods to check if
services are up and running, methods to check if files exist, and helper methods
to interact with different components. They're often used in Chef recipes.

Of all the libraries used in Omnibus GitLab, there are some special ones: the
primary GitLab module and all the component-specific libraries that it invokes.
The component specific libraries contains methods that do the job of parsing the
configuration file for settings defined for their corresponding components. The
primary GitLab module contains methods that co-ordinate this. It is responsible
for identifying default values, invoking component-specific libraries, merging
the default values and user specified values, validating them, and generating
additional configurations based on their initial values. Every top level
component that's shipped by Omnibus GitLab package gets added to this module, so
that they can be mentioned in configuration file and default attributes and get
parsed correctly.

### runit

GitLab uses [runit](http://smarden.org/runit/) recipes for the purpose of
service management and supervision. runit recipes do the job of identifying the
init system used by the OS and perform basic service management tasks like
creating necessary service files for GitLab, service enabling, and service
reloading. runit provides `runit_service` definitions that can be used by other
recipes to interact with services. (`/files/gitlab-cookbook/runit`)

### Services

Services are software processes that we run using the runit process
init/supervisor. You are able to check their status, start, stop, and restart
them using the `gitlab-ctl` commands. Recipes may also disable or enable these
services based on their process group and the settings/roles that have been
configured for the instance of GitLab. The list of services and the service
groups associated with them can be found in
[`files/gitlab-cookbooks/package/libraries/config/services.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/package/libraries/config/services.rb).

## Additional `gitlab-ctl` commands

Omnibus, by default, provides some wrapper commands like `gitlab-ctl reconfigure`
and `gitlab-ctl restart` to manage the GitLab instance. There are some
additional [wrapper commands](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-ctl-commands)
that target some specific use-cases defined in the Omnibus GitLab repository.
These commands get used with the general `gitlab-ctl` command to perform certain
actions like running database migrations or removing dormant accounts and similar
not-so-common tasks.

## Tests

Omnibus GitLab repository uses ChefSpec to [test the cookbooks and recipes](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/spec/) it ships. The usual strategy is to check a recipe to see if it behaves correctly in two (or more) conditions: when user doesn't specify any corresponding configuration, (i.e. when defaults are used) and when user specified configuration is used. Tests may include checking if files are generated in correct locations, services are started/stopped/notified, correct binaries are invoked, and correct parameters are being passed to method invocations. Recipes and library methods have tests associated with them. Omnibus GitLab also uses some support methods or macros to help in the testing process. The tests are defined compatible for parallelization, where possible, to decrease the time required for running the entire test suite.

So, of the components described above, some (such as software definitions, project metadata, and tests) find use during the package building, in a build environment, and some (such as Chef cookbooks and recipes, GitLab configuration file, runit, and `gitlab-ctl` commands) are used to configure the user's installed instance.

## Work life cycle of Omnibus GitLab

### What happens during package building

The type of packages being built depends on the OS the build process is run. If build is done on a Debian environment, a `.deb` package will be created. What happens during package building can be summarized to the following steps

1. Fetching sources of dependency softwares:
   1. Parsing software definitions to find out corresponding versions.
   1. Getting source code from remotes or cache.
1. Building individual software components:
   1. Setting up necessary environment variables and flags.
   1. Applying patches, if applicable.
   1. Performing the build and installation of the component, which involves installing it to appropriate location (inside `/opt/gitlab`).
1. Generating license information of all bundled components - including external softwares, Ruby gems, and JS modules. This involves analysing definitions of each dependencies as well as any additional licensing document provided by the components (like `licenses.csv` file provided by GitLab Rails)
1. Checking license of the components to make sure we are not shipping a component with a non-compatible license
1. Running a health check on the package to make sure the binaries are linked against available libraries. For bundled libraries, the binaries should link against them and not the one available globally.
1. Building the package with contents of `/opt/gitlab`. This makes use of the metadata given inside [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/config/projects/gitlab.rb) file. This includes package name, version, maintainer, homepage, and information regarding conflicts with other packages.

#### Caching

Omnibus uses two types of cache to optimize the build process: one to store the software artifacts (sources of dependent softwares), and one to store the project tree after each software component is built

##### Software artifact cache (for GitLab Inc builds)

Software artifact cache uses an Amazon S3 bucket to store the sources of the dependent softwares. In our build process, this cache is populated using the command `bin/omnibus cache populate`. This will pull in all the necessary software sources from the Amazon bucket and store it in the necessary locations. When there is a change in the version requirement of a software, omnibus pulls it from the original upstream and add it to the artifact cache. This process is internal to omnibus and we configure the Amazon bucket to use in [omnibus.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/omnibus.rb) file available in the root of the repository. This cache ensures availability of the dependent softwares even if their original upstream remotes go down.

##### Build cache

A second type of cache that plays an important role in our build process is the build cache. Build cache can be described as snapshots of the project tree (where the project actually gets built - `/opt/gitlab`) after each dependent software is built. Consider a project with five dependent pieces of software - A, B, C, D and E, built in that order, we're not considering the their individual dependencies. Build cache makes use of Git tags to make snapshots. After each software is built, a Git tag is computed and committed. Now, consider we made some change to the definition of software D. A, B, C and E remains the same. When we try to build again, omnibus can reuse the snapshot that was made before D was built in the previous build. Thus, the time taken to build A, B and C can be saved as it can simply checkout the snapshot that was made after C was built. Omnibus uses the snapshot just before the software which "dirtied" the cache (dirtying can happen either by a change in the software definition, a change in name/version of a previous component, or a change in version of the current component) was built. Similarly, if in a build there is a change in definition of software A, it will dirty the cache and hence A and all the following dependencies get built from scratch. If C dirties the cache, A and B gets reused and C, D and E gets built again from scratch.

This cache makes sense only if it is retained across builds. For that, we use the caching mechanism of GitLab CI. We have a dedicated runner which is configured to store its internal cache in an Amazon bucket. Before each build, we pull in this cache (`restore_cache_bundle` target in out Makefile), move it to appropriate location and start the build. It gets used by the omnibus until the point of dirtying. After the build, we pack the new cache and tells CI to back it up to the Amazon bucket (`pack_cache_bundle` in our Makefile).

Both types of cache reduce the overall build time of GitLab and dependencies on external factors.

The cache mechanism can be summarised as follows:

1. For each software dependency:
   1. Parse definition to understand version and SHA256.
   1. If the source file tarball available in artifact cache in Amazon bucket matches the version and SHA256, use it.
   1. Else, download the correct tarball from the upstream remote.
1. Get build cache from CI cache.
1. For each software dependency:
   1. If cache has been dirtied, break the loop.
   1. Else, checkout the snapshot.
1. If there are remaining dependencies:
   1. For each remaining dependency:
      1. Build the dependency.
      1. Create a snapshot and commit it.
1. Push back the new build cache to CI cache.

### What happens during `gitlab-ctl reconfigure`

One of the commonly used commands while managing a GitLab instance is `gitlab-ctl reconfigure`. This command, in short, parses the config file and runs the recipes with the values supplied from it. The recipes to be run are defined in a file called `dna.json` present in the `embedded` folder inside the installation directory (This file is generated by a software dependency named `gitlab-cookbooks` that's defined in the software definitions). In case of GitLab CE, the cookbook named `gitlab` will be selected as the master recipe, which in-turn invokes all other necessary recipes, including runit. In short, reconfigure is basically a chef-client run that configures different files and services with the values provided in configuration template.
