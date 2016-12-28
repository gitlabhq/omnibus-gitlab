# Omnibus-GitLab Architecture and Components

Omnibus-GitLab is a customized fork of the Omnibus project from Chef, and it uses Chef components like cookbooks and recipes to perform the task of configuring GitLab in a user's machine. [Omnibus-GitLab repository on GitLab.com](https://gitlab.com/gitlab-org/omnibus-gitlab) hosts all the necessary components of Omnibus-GitLab. These include parts of Omnibus that is required to build the package, like configurations and project metadata, and the Chef related components that will be used in a user's machine after installation.

![Omnibus-GitLab Components](components.png)

## Software Definitions

### GitLab project definition file

A primary component of the omnibus architecture is a project definition file that lists the project details and dependency relations to external softwares and libraries. The main components of this project definition file are
 1. Project metadata - name, description, etc.
 2. License details of the project
 3. Dependency list - List of external tools and softwares which are required to build/run GitLab and sometimes their metadata
 4. Global configuration variables used for installation of GitLab - Installation directory, system user, system group, etc.

`**Note:` Project definition may be found at [config/projects/gitlab.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/config/projects/gitlab.rb).

### Individual software definitions

Omnibus-GitLab follows a batteries-included style of distribution. All the software, libraries and binaries necessary for the proper functioning of a GitLab instance is provided as part of the package, in an embedded format. So another one of the major components of the omnibus architecture is the software definitions and configurations. A typical software configuration consist of the 4 parts
 1. Version of the software required.
 2. License of the software.
 3. Dependencies for the software to be built/run.
 4. Commands needed to build the software and embed it inside the package.

`**Note:` Software definitions may be found inside [config/software/](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config/software) folder

Sometimes, softwares' source code may have to be patched in order to use it with GitLab. This may be to fix a security vulnerability, add some functionality needed for GitLab, or make it work with other component of GitLab, etc. For this purpose, Omnibus-GitLab consists of a patch directory where patches for different softwares are stored.

`**Note:` Patches may be found inside the [config/patches](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config/patches) folder in the repository.

## Global GitLab configuration template

Omnibus-GitLab ships with it a single configuration file that can be used to configure each and every part of the GitLab instance, which will be installed to the user's machine. This configuration file acts as the canonical source of all configuration settings that will be applied to the GitLab instance. It lists the general settings for a GitLab instance as well as various options for different components. The common structure of this file consist of configurations specified in the format `<component>['<setting>'] = <value>`. All the available options are listed in the template, but all except the ones necessary for basic working of GitLab are commented out by default. Users may uncomment them and specify corresponding values, if necessary.


`**Note:` Global configuration template may be found at [files/gitlab-config-template/gitlab.rb.template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

## GitLab Cookbook

Omnibus-GitLab, as described earlier, uses many of the Chef components like cookbooks, attributes, resources, etc. GitLab EE uses a separate cookbook that extends from the one GitLab CE uses and adds the EE-only components. The major players in the Chef-related part of Omnibus-GitLab are the following:

### Default Attributes

Default attributes, as the name suggests, specifies the default values to different settings provided in the configuration file. These values act as fail-safe and get used if the user doesn't provide a value to a setting, and thus ensure a working GitLab instance with minimum user tweaking being necessary.

`**Note:` Default attributes are defined at [files/gitlab-cookbooks/gitlab/attributes/default.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb).

### Recipes

Recipes do most of the heavy-lifting while installing GitLab using omnibus package as they are responsible for setting up each component of the GitLab ecosystem in a user's machine. They create necessary files, directories and links in their corresponding locations, set their permissions and owners, configure, start and stop necessary services, notify these services when files corresponding to them change, etc. A master recipe, named `default` acts as the entry point and it invokes all other necessary recipes for various components and services.

`**Note:` Recipes may be found inside [files/gitlab-cookbooks/gitlab/recipes](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/recipes) folder in the repository.

### Definitions

Definitions can be considered as global-level macros that are available across recipes. Some common uses for definitions are defining the ports used for common services, listing important directories that may be used by different recipes, etc. They define resources that may be reused by different recipes.

`**Note:` Definitions may be found inside [files/gitlab-cookbooks/gitlab/definitions](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/definitions) folder in the repository.

### Templates for configuration of components

As mentioned earlier, Omnibus-GitLab provides a single configuration file to tweak all components of a GitLab instance. However, architectural design of different components may require them to have individual configuration files residing at specific locations. These configuration files have to be generated from either the values specified by the user in general configuration file or from the default values specified. Hence, Omnibus-GitLab ships with it templates of such configuration files with placeholders which may be filled by default values or values from user. The recipes do the job of completing these templates, by filling them and placing them at necessary locations.

`**Note:` Software configuration templates may be found inside [files/gitlab-cookbooks/gitlab/templates](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/templates) folder in the repository.

### General library methods

Omnibus-GitLab also ships some library methods that primarily does the purpose of code reuse. This include methods to check if services are up and running, methods to check if files exist, helper methods to interact with different components, etc. They are often used in Chef recipes.

Of all the libraries used in Omnibus-GitLab, there are some special ones: the primary GitLab module and all the component-specific libraries that it invokes. The component specific libraries contains methods that do the job of parsing the configuration file for settings defined for their corresponding components. The primary GitLab module contains methods that co-ordinate this. It is responsible for identifying default values, invoking component-specific libraries, merging the default values and user specified values, validating them, generating additional configurations based on their initial values, etc. Every top level component that is shipped by Omnibus-GitLab package gets added to this module, so that they can be mentioned in configuration file and default attributes and get parsed correctly.

`**Note:` Libraries may be found inside [files/gitlab-cookbooks/gitlab/libraries](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/libraries) folder in the repository.

### Runit

GitLab uses [runit](http://smarden.org/runit/) recipes for the purpose of service management and supervision. Runit recipes do the job of identifying the init system used by the OS and perform basic service management tasks like creating necessary service files for GitLab, service enabling, service reloading, etc. Runit provides `runit_service` definitions that can be used by other recipes to interact with services.
(/files/gitlab-cookbook/runit)

## Additional gitlab-ctl commands

Omnibus, by default, provides some wrapper commands like `gitlab-ctl reconfigure`, `gitlab-ctl restart`, etc.to manage the GitLab instance. There are some additional wrapper commands that targets some specific use-cases defined in the Omnibus-GitLab repository. These commands get used with the general `gitlab-ctl` command to perform certain actions like running database migrations or removing dormant accounts and similar not-so-common tasks.

`**Note:` Additional wrapper commands may be found inside [files/gitlab-ctl-commands](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-ctl-commands) folder in the repository.

## Tests

Omnibus-GitLab repository uses ChefSpec to test the cookbooks and recipes it ships. The usual strategy is to check a recipe to see if it behaves correctly in two (or more) conditions: when user doesn't specify any corresponding configuration, (i.e. when defaults are used) and when user specified configuration is used. Tests may include checking if files are generated in correct locations, services are started/stopped/notified, correct binaries are invoked, correct parameters are being passed to method invocations, etc. Recipes and library methods have tests associated with them. Omnibus-GitLab also uses some support methods or macros to help in the testing process. The tests are defined compatible for parallelization, where possible, to decrease the time required for running the entire test suite.

`**Note:` Tests may be found inside [spec](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/spec/) folder in the repository.

So, of the components described above, some (software definitions, project metadata, tests, etc.) find use during the package building, in a build environment, and some (Chef cookbooks and recipes, GitLab configuration file, Runit, gitlab-ctl commands, etc.) are used to configure the user's installed instance.

## Work life cycle of Omnibus-GitLab
### What happens during Package Building

When packages are built using the `omnibus build` command, a few steps are completed in the background. The main step of this is collecting all the dependency softwares whose definitions are available. This involves parsing the software definitions, finding out the necessary version, getting their corresponding source codes from prescribed URL, and building them as specified in those software definitions. This is followed by a HealthCheck, that checks the licenses of all the dependencies and see if they are all present, valid, and compatible with the Omnibus-GitLab licensing. The next step involves actual package building, which depends on the host OS in which the command is run, i.e. a .deb package is created if ran on a Debian OS. Package building uses the metadata provided in the project definition like name, description, maintainer, conflict and replace relations, etc. The package consists of all the defined softwares embedded in it, global configuration file, the necessary cookbooks, and other package specific control files, metadata, and scripts.

### What happens during `gitlab-ctl reconfigure`

One of the commonly used commands while managing a GitLab instance is `gitlab-ctl reconfigure`. This command, in short, parses the config file and runs the recipes with the values supplied from it. The recipes to be run are defined in a file called `dna.json` present in the `embedded` folder inside the installation directory (This file is generated by a software dependency named `gitlab-cookbooks` that is defined in the software definitions). In case of GitLab CE, the cookbook named `gitlab` will be selected as the master recipe, which in-turn invokes all other necessary recipes, including runit. So, reconfigure is basically a chef-client run that configures different files and services with the values provided in configuration template.
