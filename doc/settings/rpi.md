---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Running on a Raspberry Pi
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

In order to run GitLab Community Edition on a Raspberry Pi, you need the newest
Pi 4 with at least 4 GB of RAM for best results. You might be able to run GitLab
on lower resources, like a Pi 3 or newer, but it is not recommended. We do not
package for older Pis, as their CPU and RAM are insufficient.

Starting from GitLab version 18.0, we will no longer provide 32-bit packages for Raspberry Pi.
You should use 64-bit Raspberry Pi OS and [install the `arm64` Debian packages](https://docs.gitlab.com/install/package/debian/).
For information on backing up data on a 32-bit OS and restoring it to a 64-bit OS, see
[Upgrading operating systems for PostgreSQL](https://docs.gitlab.com/administration/postgresql/upgrading_os/).

## Configure swap

To ensure the device has enough memory available, expand the swap space to 4 GB.

## Install GitLab

The recommended and supported way to install GitLab is by using the GitLab
official repository.

Only the [official Raspberry Pi 64-bit distribution](https://www.raspberrypi.com/software/) is
supported.

### Install GitLab via the official repository

Visit the [installation page](https://about.gitlab.com/install/), choose
Debian, and follow the instructions to install GitLab.

### Manually download GitLab

If your distribution of choice is Debian-based, you
can [manually download](https://docs.gitlab.com/update/package/#upgrade-with-a-downloaded-package)
GitLab and install it.

## Reduce running processes

If you find that your Pi is struggling to run GitLab, you can reduce
some running processes:

1. Open `/etc/gitlab/gitlab.rb` and change the following settings:

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

You can boost GitLab performance with a few settings.

### Use a proper hard drive

GitLab will perform best if you mount `/var/opt/gitlab` and the swapfile from a
hard drive rather than the SD card. You can attach an external hard drive to the
Pi using the USB interface.

### Use external services

You can improve the GitLab performance on the Pi by connecting GitLab to
external [database](database.md#using-a-non-packaged-postgresql-database-management-server)
and [Redis](https://docs.gitlab.com/administration/redis/standalone/) instances.
