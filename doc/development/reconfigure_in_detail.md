---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# What happens when `gitlab-ctl reconfigure` is run?

Omnibus GitLab uses [Cinc](https://cinc.sh/) under the hood,
which is a free-as-in-beer distribution of the open source software of [Chef Software Inc](https://docs.chef.io/). 

In very basic terms, a [Cinc client](https://cinc.sh/start/client/) run
happens when `gitlab-ctl reconfigure` is run. This document elaborates
the process and details the flow of control during a `gitlab-ctl reconfigure`
run.

`gitlab-ctl reconfigure` is defined in the
[`omnibus-ctl` project](https://gitlab.com/gitlab-org/build/omnibus-mirror/omnibus-ctl/-/blob/0.6.0.1/lib/omnibus-ctl.rb#L517)
and as mentioned above, it performs a
[`cinc-client` run](https://gitlab.com/gitlab-org/build/omnibus-mirror/omnibus-ctl/-/blob/0.6.0.1/lib/omnibus-ctl.rb#L501)
under the hood in [the local mode](https://docs.chef.io/ctl_chef_client/#run-in-local-mode) (using the `-z` flag). This invocation takes
two files as inputs:

- A configuration file named [`solo.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/solo.rb).
- An attribute file named `dna.json`, which is created during build time and loads:
  - For CE, the [`gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab) cookbook.
  - For EE, the [`gitlab-ee`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab-ee) cookbook.

Cinc then follows its [two-pass model of execution](https://coderanger.net/two-pass/) for the selected cookbook.

In the load phase, the main cookbook and its dependency cookbooks (mentioned in
the `metadata.rb` file) are loaded. The attributes mentioned in the default
attribute files of these cookbooks are loaded (thus populating the `node` object
with the default values specified in those attribute files) and the custom
resources are all made available for use. Control then moves to the
execution phase. In the `dna.json` file, we specify the cookbook name as the
`run_list`, which makes Cinc use the default recipe as the only entry in the run
list.

The `gitlab-ee` cookbook extends the `gitlab` cookbook with EE-only
features. For explanation purposes, let's first look at the
[`gitlab` cookbook's default recipe](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/recipes/default.rb).

## The default recipe

The functionality in the default recipe can be summarized as below:

1. Call the `config` recipe to load the attributes from `gitlab.rb` and fully
   populate the `node` object.
1. Check for any deprecations and exit early.
1. Check for any problematic settings in the run environment. For example,
   if `LD_LIBRARY_PATH` is defined it can interfere with the included
   libraries, how software links against them, and raise warnings.
1. Check for non-UTF-8 locales and raise warnings.
1. Create and configure necessary base directories like `/etc/gitlab` (unless
   explicitly disabled), `/var/opt/gitlab`, and `/var/log/gitlab`.
1. Call other necessary helper recipes and enable or disable recipes for different
   services, etc.

Note that this summary is not complete. Check out the default recipe code to
learn more.

### The config recipe

The config recipe populates the `node` object with the
final values for various settings after merging static default values,
computed default values, and user values specified
in `/etc/gitlab/gitlab.rb` file.

In the above statement, we mention two types of default values:

- **Static:** Static default values are specified in various
  attribute files in different cookbooks and are independently set.
- **Computed:** Computed default values are used in scenarios where the
  default value for a setting depends on either the static default
  value or user-specified value of another setting.

For example, `gitlab_rails['gitlab_port']` defaults to the static
value `80`. It translates to `production.gitlab.port` in the rendered
`gitlab.yml` file that configures the GitLab Rails listener port. The
`gitlab_rails['pages_host']` and `gitlab_rails['pages-port']` values,
which inform GitLab Rails about GitLab Pages, depend on the user
specified value in from `pages_external_url`. The computation of these
default values may only happen **_after_** `gitlab.rb` gets parsed.

#### What goes in to the `gitlab.rb` file?

Omnibus GitLab uses a module named `Gitlab` to store the settings specified in
`gitlab.rb`. This module, which extends `Mixlib::Config` module, can work as a
configuration hash. In the
[definition of this module](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/package/libraries/config/gitlab.rb),
we register the various roles, attribute blocks, and top-level attributes that
can be specified in `gitlab.rb`. The code for this registration is specified in
the `SettingsDSL` module, and is extended by `GitLab` module.

When `Gitlab.from_file` is called in the config recipe, the settings from
`gitlab.rb` are parsed and loaded to the `Gitlab` object, and are accessible via
`Gitlab['<setting_name>']`.

Once `gitlab.rb` has been parsed and its values are available in `Gitlab`
object, we can compute the default values of settings dependent on other settings.

#### Computation of default values

Each component with attributes that require calculation specify a library file
at registration. One method in this file, `parse_variables`, validates user-provided
input and, in typical usage, sets default values if the user did not already specify
a value. It also detects bad configuration and raises errors.

As mentioned above, `parse_variables` sets default values based on static
defaults or user-provided values in related settings. The default values
from these related settings are available in the `node` object after the load
phase of the Cinc run. This `node` object, while available in the recipe, is
not available in the libraries. To make the static default values available
in the libraries, we attach the `node` object to the `GitLab` object in
the config recipe with the code below:

```ruby
Gitlab[:node] = node
```

With this, the static default values of attributes can be accessed in the libraries
using `Gitlab[:node]['<top-level-key>'][<setting>]`.

It is important to note that:

- The `Gitlab` object stores keys as they are mentioned in `gitlab.rb`.
- `node` stores them based on the defined nesting attribute-block-attribute hierarchy.
 
So, `gitlab_rails` settings from
`gitlab.rb` are available as `Gitlab['gitlab_rails'][*]` while default values of
those settings from attribute files are available at
`Gitlab[:node]['gitlab']['gitlab_rails']`. The `gitlab_rails` key is specified
under the `gitlab` attribute block, so an extra layer of nesting is present
while accessing it via `node`.

While the `Gitlab` object is technically only supposed to hold the settings
specified in `gitlab.rb`, when computing default values of settings based on
other settings, we usually put them under `Gitlab` key itself.
[Issue #3932](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3923) is open to change
this behavior.

#### Handling of secrets

Many attributes required for GitLab functionality are secrets that need to
persist across reconfigure runs and, in multi-node setups, across different
nodes. Moreover, if the user did not specify values for these secrets then
Omnibus GitLab must create them to function. For this purpose, each library file
specifies a `parse_secrets` method similar to the `parse_variables` method. This
method generates secrets, unless explicitly disabled, if none have been specified
in the `gitlab.rb` file.

These secrets are written, unless explicitly disabled, to a file named
`/etc/gitlab/gitlab-secrets.json`. This file is read by subsequent reconfigure
runs and the secret persists across every reconfigure run.

#### Update the node object with final attribute list

After all libraries parse their respective attributes and secrets, the
final configuration is ready to merge with default attributes already
present in `node`. The `node.consume_attributes` method merges the
final configuration with the default configuration populated in the load
phase. Any configuration read from `gitlab.rb` or computed in the libraries
overwrite the values for keys matched in the `node` object. At this point,
the `node` object contains the final attribute list.

#### `gitlab-cluster.json` file

A user configures the system with `gitlab.rb` to match the requirement. In
certain scenarios, however, we need to perform alterations without changes
to the `gitlab.rb` file. Omnibus GitLab writes to a different file,
`/etc/gitlab/gitlab-cluster.json`, that overrides user-specified values in
`gitlab.rb`. The `gitlab-ctl` command or a reconfigure dynamically populates
this file and it gets read and merged over the `node` attributes at the end
of the config recipe.

The `gitlab-ctl geo promote` command, when used on a multi-node PostgreSQL
instance with Patroni, must disable the Patroni standby server. In this
example, the standby server would normally be disabled via
`patroni['standby_cluster']['enable']` in `gitlab.rb`. The `gitlab.rb` file
should remain read-only for the duration of the Cinc run, so this setting
is changed in the `gitlab-cluster.json` file. Future reconfigure runs parse
the `gitlab-cluster.json` file at the end and `node['patroni']['standby_cluster']['enable']`
will evaluate `false`.

The Cinc run executes helper and service-specific recipes after
the config recipe. Once these are complete, the node object is
fully populated and may be used in recipes and resources.

The default recipe in EE cookbook essentially calls `gitlab::default` recipe,
and then handles the EE-specific components separately.
