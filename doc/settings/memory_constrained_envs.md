---
stage: Data Stores
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Running GitLab in a memory-constrained environment
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab requires a significant amount of memory when running with all features enabled.
There are use-cases such as running GitLab on smaller installations where not all functionality
is required. Examples include:

- Running GitLab for personal use or very small teams.
- Using a small instance on a cloud provider for cost savings.
- Using resource-constrained devices like the Raspberry PI.

With some adjustments, GitLab can run comfortably on much lower specifications than described in
[minimum requirements](https://docs.gitlab.com/install/requirements/) or the
[reference architectures](https://docs.gitlab.com/administration/reference_architectures/).

While most GitLab parts should be
functional with these settings in place, you may experience unexpected degradation
of both product functionality and performance.

{{< alert type="note" >}}

The following sections describe how to run GitLab with up to 5 developers with individual Git repositories no larger than 100 MB.

{{< /alert >}}

## Minimum requirements for constrained environments

The minimum expected specs with which GitLab can be run are:

- Linux-based system (ideally Debian-based or RedHat-based)
- 4 CPU cores of ARM7/ARM64 or 1 CPU core of AMD64 architecture
- Minimum 2 GB of RAM + 1 GB of SWAP, optimally 2.5 GB of RAM + 1 GB of swap
- 20 GB of available storage
- A storage with a good random I/O performance with an order of preference:
  - [SSD](https://en.wikipedia.org/wiki/Solid-state_drive)
  - [eMMC](https://magazine.odroid.com/article/emmc-memory-modules-a-simple-guide/)
  - [HDD](https://en.wikipedia.org/wiki/Hard_disk_drive)
  - [high-performance A1-type SD card](https://www.sdcard.org/developers/sd-standard-overview/application-performance-class/)

Of the above list, the single-core performance of the CPU
and the random I/O performance of the storage have the highest impact.
Storage is especially relevant since in a constrained environment we expect some
amount of memory swapping to happen which puts more pressure on a used disk.
A common problem for the limited performance of small platforms is very slow disk storage,
which leads to a system-wide bottleneck.

With these minimal settings, the system should use swap during regular operation.
Since not all components are used at the same time, it should provide acceptable performance.

## Validate the performance of your system

There are number of tools available that allow you to validate the performance of your Linux-based system.
One of the projects that can aid with checking the performance of your system is [sbc-bench](https://github.com/ThomasKaiser/sbc-bench).
It describes all caveats of system testing and the impact of different behaviors on the performance of your system,
which is especially important when running GitLab in an embedded system. It can be used as a way to validate if the performance
of your system is good enough to run GitLab on a constrained environment.

These systems provide adequate performance to run a small installations of GitLab:

- [Raspberry PI 4 2 GB](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/).
- [DigitalOcean Basic 2 GB with SSD](https://www.digitalocean.com/pricing).
- [Scaleway DEV1-S 2 GB/20 GB](https://www.scaleway.com/en/pricing/).
- [GCS e2-small](https://cloud.google.com/compute/docs/machine-resource).

## Configure Swap

Before you install GitLab you need swap to be configured. Swap is a dedicated space on disk that
is used when physical RAM is full. When a Linux system runs out of RAM,
inactive pages are moved from RAM to the swap space.

Swap usage is often considered a problem as it can increase latency. However,
due to how GitLab functions, much of the memory that is allocated is not frequently accessed. Using
swap allows the application to run and function normally, and use swap only from time to time.

A general guideline is to configure swap to be around 50% of the available memory. For memory constrained
environments, it is advised to configure at least 1 GB of swap for the system. There are a number of guides
on how to do it:

- [How to Add Swap Space on Ubuntu 20.04](https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-20-04/)
- [How to Add Swap Space on CentOS 7](https://linuxize.com/post/how-to-add-swap-space-on-centos-7/)

Once configured, you should validate that swap is properly enabled:

```shell
free -h
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       115Mi       1.4Gi       0.0Ki       475Mi       1.6Gi
Swap:         1.0Gi          0B       1.0Gi
```

You might also configure how often the system will use the swap space with adjusting `/proc/sys/vm/swappiness`.
Swappiness ranges between `0` and `100`. The default value is `60`. A lower value reduces Linux's preference to free anonymous memory pages and write them to swap, but it increases its preference for doing the same with file-backed pages:

1. Configure it in the current session:

   ```shell
   sudo sysctl vm.swappiness=10
   ```

1. Edit `/etc/sysctl.conf` to make it permanent:

   ```shell
   vm.swappiness=10
   ```

## Install GitLab

In a memory-constrained environment, you should consider which GitLab distribution is right for you.

[GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/) comes with significantly more features
than [GitLab Community Edition (CE)](https://about.gitlab.com/install/?version=ce), but all these additional features
increase compute and memory requirements.

When memory consumption is the primary concern, install GitLab CE. You can
always [upgrade to GitLab EE](https://docs.gitlab.com/update/convert_to_ee/package/) later.

## Optimize Puma

By default, GitLab runs with a configuration designed to handle many concurrent connections.

For small installations that do not require high throughput,
[disable Puma Clustered mode](https://docs.gitlab.com/administration/operations/puma/#disable-puma-clustered-mode-in-memory-constrained-environments).
This configuration runs only a single Puma process to serve the application.

In `/etc/gitlab/gitlab.rb`:

```ruby
puma['worker_processes'] = 0
```

We observed 100-400 MB of memory usage reduction with this optimization.

## Optimize Sidekiq

Sidekiq is a background processing daemon. When configured with GitLab by default
it runs with a concurrency mode of `20`. This does impact how much memory it can
allocate at a given time. It is advised to configure it to use a significantly
smaller value of `5` or `10` (preferred).

In `/etc/gitlab/gitlab.rb`:

```ruby
sidekiq['concurrency'] = 10
```

## Optimize Gitaly

Gitaly is a storage service that allows efficient access to Git-based repositories.
It is advised to configure a maximum concurrency and memory limits enforced by Gitaly.

In `/etc/gitlab/gitlab.rb`:

```ruby
gitaly['configuration'] = {
    concurrency: [
      {
        'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
        'max_per_repo' => 3,
      }, {
        'rpc' => "/gitaly.SSHService/SSHUploadPack",
        'max_per_repo' => 3,
      },
    ],
    cgroups: {
        repositories: {
            count: 2,
        },
        mountpoint: '/sys/fs/cgroup',
        hierarchy_root: 'gitaly',
        memory_bytes: 500000,
        cpu_shares: 512,
    },
}

gitaly['env'] = {
  'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
}
```

## Disable monitoring

GitLab enables all services by default to provide a complete DevOps solution without any additional configuration.
Some of the default services, like monitoring, are not essential for GitLab to function and can be disabled to save memory.

In `/etc/gitlab/gitlab.rb`:

```ruby
prometheus_monitoring['enable'] = false
```

We observed 200 MB of memory usage reduction configuring GitLab this way.

## Configure how GitLab handles memory

GitLab consists of many components (written in Ruby and Go),
with GitLab Rails being the biggest one and consuming the most of memory.

GitLab Rails uses [jemalloc](https://github.com/jemalloc/jemalloc) as a memory
allocator. [jemalloc](https://github.com/jemalloc/jemalloc) preallocates memory in
bigger chunks that are also being held for longer periods in order to improve performance.
At the expense of some performance loss, you can configure GitLab to free memory right after
it is no longer needed instead of holding it for a longer periods.

In `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}

gitaly['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}
```

We observed much more stable memory usage during the execution of the application.

## Disable additional in-application monitoring

GitLab uses internal data structures to measure different aspects of itself.
These features are no longer needed if monitoring is disabled.

To disable these features you need to go to Admin Area of GitLab
and disable the Prometheus Metrics feature:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Metrics and profiling**.
1. Expand **Metrics - Prometheus**.
1. Disable **Enable Prometheus Metrics**.
1. Select **Save changes**.

## Configuration with all the changes

1. If you apply everything described so far, your `/etc/gitlab/gitlab.rb` file
   should contain the following configuration:

   ```ruby
   puma['worker_processes'] = 0

   sidekiq['concurrency'] = 10

   prometheus_monitoring['enable'] = false

   gitlab_rails['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
   }

   gitaly['configuration'] = {
     concurrency: [
       {
         'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
         'max_per_repo' => 3,
       }, {
         'rpc' => "/gitaly.SSHService/SSHUploadPack",
         'max_per_repo' => 3,
       },
     ],
     cgroups: {
       repositories: {
         count: 2,
       },
       mountpoint: '/sys/fs/cgroup',
       hierarchy_root: 'gitaly',
       memory_bytes: 500000,
       cpu_shares: 512,
     },
   }
   gitaly['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000',
     'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
   }
   ```

1. After you make all these changes, reconfigure GitLab to use the new settings:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   This operation could take a while, since GitLab did not work
   with memory conservative settings up-to this point.

## Performance results

After applying the above configuration, you can expect the following memory usage:

```plaintext
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       1.7Gi       151Mi        31Mi       132Mi       102Mi
Swap:         1.0Gi       153Mi       870Mi
```
