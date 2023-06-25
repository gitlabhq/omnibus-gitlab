---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Create Patches

You can manually modify an external dependency to:

- Make sure that dependency works with Omnibus embedded packaging.
- Fix an issue that an upstream maintainer has not fixed.

## Bootstrap patch files

Omnibus has a specific [DSL](https://github.com/chef/omnibus#software) and
conventions to ship and apply patches automatically as part of the build
process.

To apply patch files, store `.patch` files that contain the changes in a
specific directory structure using the `patch` DSL method:

```plaintext
config/patches/<software-name>
```

For example, for a patch applied during the execution of
`gitlab-rails`, store the `.patch` files in:

```plaintext
config/patches/gitlab-rails
```

## Create a patch

To create a patch file, you can use:

- The `diff` command to compare an original file with a modified file.
- Git to output a patch based one or more commits.

### Use `diff` to create a patch

To create a patch file using the `diff` command:

1. Duplicate the file you are changing and give the new file a new name.
1. Change the original file.

```shell
diff -Naur <original_file> <new_file> > <patch_filename>.patch
```

### Use Git to create a patch

Use the `git diff` command to create a patch file between two Git commits.
You must know both commit IDs.

```shell
git diff <commitid1> <commitid2> > <patch_filename>.patch
```

You can also create a patch file based on one Git commit and the base HEAD.

```shell
git diff <commitid1> > <patch_filename>.patch
```

## Use the patch

To patch one or more files:

1. Get the original files by downloading, bundle installing, or using a similar method.
1. Add the following line to each original file:

   ```shell
   patch source: '<patch_filename>.patch', target: "#{<install_directory>}/embedded/<target_file>.txt"
   ```
