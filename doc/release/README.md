# Omnibus-gitlab release process

Our main goal is to make it clear which version of GitLab is in an omnibus package.

## On your development machine

- Pick a tag of GitLab to package (e.g. `v6.6.0`).
- Create a release branch in omnibus-gitlab (e.g. `6-6-stable`).
- If the release branch already exists, for instance because you are doing a
  patch release, make sure to pull the latest changes to your local machine.

```
git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # existing release branch
```

- Use `support/set-revisions` to set the revisions in `config/software/...`. It
will take tag names and look up the Git SHA1's, and set the download sources to
dev.gitlab.org. Use `set-revisions --ee` for an EE release.

```
# usage: set-revisions [--ee] GITLAB_RAILS_REF GITLAB_CI_REF GITLAB_SHELL_REF
support/set-revisions v6.6.0 v6.6.0 v1.2.3
```

- Commit the new version to the release branch


```shell
git commit -v config/software
```

Create an annotated tag on omnibus-gitlab corresponding to the GitLab tag.  The
omnibus tag looks like: `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`, where
`MAJOR.MINOR.PATCH` is the GitLab version, `OTHER` can be something like `ce`,
`ee` or `rc1` (or `rc1.ee`), and `OMNIBUS_RELEASE` is a number (starting at 0).

> Do NOT use `-` in the omnibus-gitlab tag anywhere.

Example tags, with 'upstream tag => omnibus tag sequence':

- `v7.10.4` => `7.10.4+ce.0`, `7.10.4+ce.1`, ...
- `v7.10.4-ee` => `7.10.4+ee.0`, `7.10.4+ee.1`, ...
- `v7.11.0.rc1-ee` => `7.11.0+rc1.ee.0`, `7.11.0+rc1.ee.1`, ...

```shell
git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
```

- Push the branch and the tag to the main repository and dev.gitlab.org.
  Pushing an annotated tag to dev.gitlab.org triggers a package release.

```shell
git push git@gitlab.com:gitlab-org/omnibus-gitlab.git  6-6-stable 6.6.0.omnibus
git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git  6-6-stable 6.6.0.omnibus
```

- Make sure that the master branch of omnibus-gitlab has the latest changes from the omnibus-gitlab CE stable branch

```shell
git checkout master
git merge 6-6-stable
```

## Publishing the packages

The package are being built at https://ci.gitlab.org .

- When the build is done, update the download page with the package URL's and SHA1 hashes.

See a previous [CE example](https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/141)
and [EE example](https://dev.gitlab.org/gitlab/gitlab-ee/commit/7301417820404f92ca7c0a9940408ef414ef3c01).

[the gitlab-rails version in omnibus-gitlab]: ../master/config/software/gitlab-rails.rb#L20
[the gitlab-shell version]: ../master/config/software/gitlab-shell.rb#L20
[the gitlab-ci version]: ../master/config/software/gitlab-ci.rb#L19
[the source]: ../master/config/software/gitlab-rails.rb#L34
