---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Creating Patches

It can happen that you may need to manually modify an external dependency for it
to work correctly in the context of a Omnibus embedded packaging, or even to
fix an issue that the upstream maintainer have not either accepted or still
taking longer to review and ship.

## Bootstrapping

Omnibus has a specific [DSL](https://github.com/chef/omnibus#software) and
conventions to ship and apply patches automatically as part of the building
process.

You will store `.patch` files that contain the changes in a specific
directory structure and with the help of the `patch` DSL method, will apply
the file(s) to reflect the desired changes:

```plaintext
config/patches/<software-name>
```

As example, for a patch that will be applied during the execution of
`gitlab-rails`, you will store `.patch` files in:

```plaintext
config/patches/gitlab-rails
```

## Creating a patch

There are two easy ways to create a patch file. You can use the `diff` command
and compare a original with a modified file (i.e. `target.rb` with
`target.rb.original`) or you can use Git to output a patch based one or more
commits.

### Diff command

To create a patch file using the diff and the previous example, duplicate the
file you are changing with a new name, and make the change to the old one.

```shell
diff -Naur target.rb.original target.rb > my_awesome_change.patch
```

### Git command

To create a patch file based on Git commits, you must get the hash from both
(or just the earliest one if you are comparing with base HEAD).

```shell
# to generate a patch between two commits
git diff commitid1 commitid2 > my_awesome_change.patch

# to generate a patch between the HEAD and a specific commits
git diff commitid1 > my_awesome_change.patch
```

## Using the patch

To patch one or more files, you must first execute any operation in your
software definition that provides the original files like downloading,
bundle installing etc, and then add something similar to:

```shell
patch source: 'my_awesome_change.patch', target: "#{install_dir}/embedded/target_file.txt"
```
