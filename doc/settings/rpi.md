---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

To ensure the device has enough memory available, expand the swap space to 4 GB.

## Install GitLab

Starting from GitLab version 18.0, we no longer provide 32-bit packages for Raspberry Pi.

You should use [64-bit Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/) and
[install GitLab using the `arm64` Debian packages](https://docs.gitlab.com/install/package/debian/).

For information on backing up data on a 32-bit OS and restoring it to a 64-bit OS, see
[Upgrading operating systems for PostgreSQL](https://docs.gitlab.com/administration/postgresql/upgrading_os/).

## Reduce running processes

If you find that your Pi is struggling to run GitLab, you can reduce
some running processes.

For more information, see how to run GitLab in a [memory-constrained environment](memory_constrained_envs.md).

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
