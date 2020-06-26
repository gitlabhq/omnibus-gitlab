---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Running on a Raspberry Pi

> Debian Buster support was added in Omnibus GitLab 13.1.

In order to run GitLab Community Edition on a Raspberry Pi, you need the newest
Pi 4 with at least 4GB of RAM for best results. You might be able to run GitLab
on lower resources, like a Pi 2 or newer, but it is not recommended. We do not
package for older Pis, as their CPU and RAM are insufficient.

The only supported architecture is `armhf`. For `arm64` support, see
[this epic](https://gitlab.com/groups/gitlab-org/-/epics/2370).

## Configure Swap

Even with a newer Pi, the first setting you will want to change is to ensure
the device has enough memory available by expanding the swap space to 4GB.

On Raspbian, swap can be configured in `/etc/dphys-swapfile`.
See [the manpage](http://manpages.ubuntu.com/manpages/bionic/man8/dphys-swapfile.8.html#config) for available settings.

## Install GitLab

The recommended and supported way to install GitLab is by using GitLab's
official repository.

Only the [official Raspberry Pi distribution](https://www.raspberrypi.org/downloads/) is
supported.

### Install GitLab via the official repository

Visit the [installation page](https://about.gitlab.com/install/), choose
Raspberry Pi OS, and follow the instructions to install GitLab.

### Manually download GitLab

If your distribution of choice is other than Raspbian, but Debian-based, you
can [manually download](../manual_install.md)
GitLab and install it.

## Reduce running processes

If you find that your Pi is struggling to run GitLab, you can reduce
some running processes:

1. Open `/etc/gitlab.gitlab.rb` and change the following settings:

   ```ruby
   # Reduce the number of running workers to the minimum in order to reduce memory usage
   puma['worker_processes'] = 2
   sidekiq['concurrency'] = 9
   # Turn off monitoring to reduce idle cpu and disk usage
   prometheus_monitoring['enable'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Additional recommendations

You can boost GitLab's performance with a few settings.

### Use a proper harddrive

GitLab will perform best if you mount `/var/opt/gitlab` and the swapfile from a
hard drive rather than the SD card. You can attach an external hard drive to the
Pi using the USB interface.

### Use external services

You can improve the GitLab performance on the Pi by connecting GitLab to
[external database](database.md#using-a-non-packaged-postgresql-database-management-server)
and [Redis](redis.md#setting-up-a-redis-only-server) instances.
