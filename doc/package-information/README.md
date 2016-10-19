# Package information

The omnibus-gitlab package is bundled with all dependencies which GitLab
requires in order to function correctly.

## Licenses

See [licensing](licensing.md)

## Defaults

The omnibus-gitlab package requires various configuration to get the
components in working order.
If the configuration is not provided, the package will use the default
values assumed in the package.

These defauts are noted in the package [defaults document](defaults.md).

## Checking the versions of bundled software

Once the omnibus-gitlab package is installed, all versions of the bundled
libraries are  located in `/opt/gitlab/version-manifest.txt`.

If you don't have the package installed, you can always check the omnibus-gitlab
[source repository], specifically the [config directory].

For example, if you take a look at the `8-6-stable` branch, you can conclude that
8.6 packages were running [ruby 2.1.8]. Or, that 8.5 packages were bundled
with [nginx 1.9.0].

## Init system detection

The omnibus-gitlab will attempt to query the underlaying system in order to
check which init system it uses.
This manifests itself as a `WARNING` during the `sudo gitlab-ctl reconfigure`
run.

Depending on the init system, this `WARNING` can be one of:

```
/sbin/init: unrecognized option '--version'
```

when the underlying init system *IS NOT* upstart.

```
  -.mount loaded active mounted   /
```

when the underlying init system *IS* systemd.

These warnings _can be safely ignored_. They are not suppressed because this
allows everyone to debug possible detection issues faster.

[source repository]: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master
[config directory]: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config
[ruby 2.1.8]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-6-stable/config/projects/gitlab.rb#L48
[nginx 1.9.0]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-5-stable/config/software/nginx.rb#L20
