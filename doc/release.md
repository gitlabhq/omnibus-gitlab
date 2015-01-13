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

- Change [the gitlab-rails version in omnibus-gitlab]. In our example that would be
  `default_version '490f99d45e0f610e88505ff0fb2dc83a557e22c5' # 6.6.0`.
- Change [the gitlab-shell version] if necessary, for example
  `default_version 'c26647b9d919085c669f49c71d0646ac23b9c9d9' # 1.9.4`.
- Change [the gitlab-ci version] if necessary, for example
  `default_version 'd69e6b7703043490e0f0f7aa458292fc2ed81fd2' # 5.1.0`.
- Change [the source] to the repo you want to build from (CE / EE)
- Commit the new version to the release branch

```shell
git commit -m 'Pin GitLab to v6.6.0' config/software/gitlab-rails.rb
```

- Create an annotated tag on omnibus-gitlab corresponding to the GitLab tag.
  GitLab tag `v6.6.0` becomes omnibus-gitlab tag `6.6.0.omnibus`.

```shell
git tag -a 6.6.0.omnibus -m 'Pin GitLab to v6.6.0'
```

- Push the branch and the tag to the main repository.

```shell
git push origin 6-6-stable 6.6.0.omnibus
```

- Make sure that the master branch has the latest CE stable tag

```shell
git checkout master
git cherry-pick $(git rev-parse 6-6-stable)

```

## On the build machines

- Log in as the build user and start a screen session

```shell
sudo su - omnibus-build
./attach.sh
```

- Check out the release tag of omnibus-gitlab.

```shell
cd ~/omnibus-gitlab
git fetch --all
git checkout 6.6.0.my-tag
```

- Check the system time; the S3 upload will fail if it is off by too much

```shell
date
```

You can adjust the time with the `date` command if necessary.

- Start the release script

```shell
./release.sh
```

This will clean the build environment, build a package and upload it to S3.

- Detach from screen: press Ctrl-a DD
- Check in on the build after 30 minutes.
- When the build is done, update the download page with the package URL's and MD5 hashes.

See a previous [CE example](https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/141)
and [EE example](https://dev.gitlab.org/gitlab/gitlab-ee/commit/7301417820404f92ca7c0a9940408ef414ef3c01).

[the gitlab-rails version in omnibus-gitlab]: ../master/config/software/gitlab-rails.rb#L20
[the gitlab-shell version]: ../master/config/software/gitlab-shell.rb#L20
[the gitlab-ci version]: ../master/config/software/gitlab-ci.rb#L19
[the source]: ../master/config/software/gitlab-rails.rb#L34
