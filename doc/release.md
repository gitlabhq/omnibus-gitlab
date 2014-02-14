# Omnibus-gitlab release process

Our main goal is to make it clear which version of GitLab is in an omnibus package.

## On your development machine

- Pick a tag of GitLab to package (e.g. `v6.6.0`).
- Create a release branch in omnibus-gitlab (e.g. `6-6-stable`).
- Change [the gitlab-rails version in omnibus-gitlab] (e.g. `version "v6.6.0"`).
- Commit the new version to the release branch

```shell
# Example:
git commit -m 'Pin GitLab to v6.6.0' config/software/gitlab-rails.rb
```

- Create an annotated tag on omnibus-gitlab corresponding to the GitLab tag.
  GitLab tag `v6.6.0` becomes omnibus-gitlab tag `6.6.0.omnibus`.

```shell
# Example:
git tag -a 6.6.0.omnibus -m 'Pin GitLab to v6.6.0'
```

- Push the branch and the tag to the main repository.

```shell
# Example:
git push origin 6-6-stable 6.6.0.omnibus
```

## On the build machines

- Check out the release branch of omnibus-gitlab.

```shell
# Example
git fetch
git checkout 6-6-stable
```

- Check the version with `git describe`.

```shell
# Example
git describe # Should start with 6.6.0.omnibus
```

- Build a package with version timestamps disabled.

```shell
# Example
OMNIBUS_APPEND_TIMESTAMP=0 bin/omnibus build project gitlab
```

[the gitlab-rails version in omnibus-gitlab]: ../config/software/gitlab-rails.rb#L20
