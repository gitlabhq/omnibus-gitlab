## Runit cookbook (modified for GitLab)

The original README can be found at the [upstream repo](https://github.com/chef-cookbooks/runit/blob/master/README.md)
and contains details about the cookbook.

Changes made to upstream version (v4.3.0) can be found at [the custom branch in
our runit-cookbook
mirror](https://gitlab.com/gitlab-org/build/omnibus-mirror/runit-cookbook/compare/v4.3.0...4.3.0-gitlab).
In addition to those, while pulling to omnibus-gitlab repo, the following
changes are made:

1. Removed all files except the custom resource definition, metadata and
   LICENSE. This means, only the `libraries` folder from upstream is used by us.

2. Added recipes for different init systems we support. The recipes
   (`runit_*.rb` files) and conf files for them (`gitlab-runsvdir.*` files) are
   available as part of our `package` cookbook.

3. The [`gitlab::runit`](files/gitlab-cookbooks/package/recipes/runit.rb) recipe
   does the init detection, and calls init system specific recipes as needed.

4. Default values for runit cookbook specifying the location of service related
   files are overridden. This is done in [attribute files of package cookbook](files/gitlab-cookbooks/package/attributes/default.rb).
   `package` cookbook is made a dependency of all other cookbooks that need
   runit, so the default attributes are propogated to them automatically.
