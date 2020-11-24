---
stage: Enablement
group: Memory
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Image scaling

GitLab runs a built-in image scaler to improve site rendering performance. It is enabled by default.

## Configure the scaler

We strive to always set sensible defaults that work with the vast majority of GitLab deployments.
However, we provide several settings that allow you to tweak image scaling to best match your
desired performance profile.

### Maximum number of image scalers

Rescaling images results in additional, short-lived processes that run on the same node Workhorse
runs on. By default, we limit the number of these processes allowed to execute simultaneously
to half the number of CPU cores on that machine or VM, but no less than two.

You may choose to set this to a fixed value instead:

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

   ```ruby
   gitlab_workhorse['image_scaler_max_procs'] = 10
   ```

1. Reconfigure for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

This would mean that if 10 images are already being processed, then the 11th request would not be
rescaled, and would be served in the original size instead. Putting a ceiling on this is important
to ensure that the system remains available even under high load.

### Maximum image file size

By default, GitLab only rescales images that are at most 250kB in size. This is to prevent excessive
memory consumption on Workhorse nodes and to keep latencies in reasonable bounds. Beyond a certain
file size, it is in fact faster overall to just serve the original image instead.

If you want to lower or raise the maximum allowed file size:

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

   ```ruby
   gitlab_workhorse['image_scaler_max_filesize'] = 1024 * 1024
   ```

1. Reconfigure for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

This would allow images up to 1MB to be rescaled (the unit is Byte).

### Disabling the image scaler

You may decide to turn off image scaling entirely. This can be accomplished by switching the respective
feature toggle off:

```ruby
Feature.disable(:dynamic_image_resizing)
```

Refer to the [Feature Flags documentation](https://docs.gitlab.com/ee/administration/feature_flags.html)
to learn how to work with feature flags.
