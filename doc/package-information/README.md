# Package information

The omnibus-gitlab package is bundled with all dependencies which GitLab
requires in order to function correctly.

## Checking the versions of bundled software

Once the omnibus-gitlab package is installed, all versions of the bundled
libraries are  located in `/opt/gitlab/version-manifest.txt`.

If you don't have the package installed, you can always check the omnibus-gitlab
[source repository], specifically the [config directory].

For example, if you take a look at the `8-6-stable` branch, you can conclude that
8.6 packages were running [ruby 2.1.8]. Or, that 8.5 packages were bundled
with [nginx 1.9.0].


[source repository]: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master
[config directory]: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config
[ruby 2.1.8]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-6-stable/config/projects/gitlab.rb#L48
[nginx 1.9.0]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-5-stable/config/software/nginx.rb#L20
