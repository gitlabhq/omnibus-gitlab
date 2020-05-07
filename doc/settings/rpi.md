# Running on a Raspberry Pi

In order to run GitLab on a Raspberry Pi, you need a Pi 2 or newer. We
recommend using a Pi 4 for best results. The Pi 1 and Pi Zero do not have enough
RAM to make running GitLab feasible.

## Configure Swap

Even with a newer Pi, the first setting you will want to change is to ensure
the device has enough memory available by expanding the swap space to 4GB.

> On Raspbian, Swap can be configured in `/etc/dphys-swapfile`.
> See [the manpage](http://manpages.ubuntu.com/manpages/bionic/man8/dphys-swapfile.8.html#config) for available settings.

## Reduce running processes

Once you have installed the GitLab package, you should change the following settings before running reconfigure.

```ruby
# Reduce the number of running workers to the minimum in order to reduce memory usage
puma['worker_processes'] = 2
sidekiq['concurrency'] = 9

# Turn off monitoring to reduce idle cpu and disk usage
prometheus_monitoring['enable'] = false
```

## Additional recommendations

### Use a proper harddrive

GitLab will perform best if you mount `/var/opt/gitlab` and the swapfile from a harddrive rather than the SDcard.

> You can attach an external harddrive to the Pi using the USB interface.

### Use external services

You can improve the GitLab performance on the Pi by connecting GitLab to external [database](database.md#using-a-non-packaged-postgresql-database-management-server) and [Redis](redis.md#setting-up-a-redis-only-server) instances.
