---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Adding a new Service to Omnibus GitLab

In order to add a new service to GitLab, you should follow these steps:

1. [Fetch and compile the software during build](#fetch-and-compile-the-software-during-build)
1. [Add a top-level configuration object for the service](#add-a-top-level-configuration-object-for-the-service)
1. [Include the service in the services list](#include-the-service-in-the-services-list)
1. [Create enable and disable recipes for the service](#create-enable-and-disable-recipes-for-the-service)
1. [Determine and document how log rotation will be handled](#determine-and-document-how-log-rotation-will-be-handled)

Optionally another common task is to add [additional configuration parsing](#additional-configuration-parsing-for-the-service)
for the service.

## Fetch and compile the software during build

You need to add a [new Software Definition](new-software-definition.md) for your
service if it is not already included in the project.

## Add a top-level configuration object for the service

The cookbooks and recipes located in `files/gitlab-cookbooks` are what get run during
`gitlab-ctl reconfigure` in instances where the Omnibus GitLab package has been
installed. This is where we will need to add the settings for a new service.

### Define the default attributes

Pick one of the existing cookbooks to configure your service within, or create a
new cookbook if your service warrants its own.

Within the cookbook there should be an `attributes/default.rb` file. This is where
you want to define the [Default Attributes](../architecture/index.md#default-attributes)
for your service. For a service you should define an `enable` option by default.

```ruby
default['gitlab']['best-service']['enable'] = false
default['gitlab']['best-service']['dir'] = '/var/opt/gitlab/best-service'
default['gitlab']['best-service']['log_directory'] = '/var/log/gitlab/best-service'
```

- `default` is how you define basic cookbook attributes.
- `['gitlab']` contains the cookbook name.
- `['best-service']` is the name of your service, at this level we use hyphens to separate words.
- `enable`, `dir`, and `log_directory` are our configuration settings, and we use underscores to separate words at this and deeper levels.
- `/var/opt/gitlab` is where the working directory and configuration files for the services are placed.
- `/var/log/gitlab` is where logs are written to for the GitLab package.

Define all your settings that you want configurable in the package here. Default
them to `nil` if you need to calculate their defaults based on other settings for
now.

### Create a configuration Mash for your service

In order for user to be able to configure your service from `/etc/gitlab/gitlab.rb`
you will need to add a top level Mash for the service.

In `files/gitlab-cookbooks/package/libraries/config/gitlab.rb` you will find the list of
`attribute` methods.

If your service exists within the attributes for the GitLab cookbook, you should
add it within the `attribute_block('gitlab')` block. Otherwise, if your service
has its own cookbook, add it above.

Add your service as an attribute, using an underscore to separate words, **even if you
used a hyphen in the default attributes.**

```ruby
attribute('best_service')
```

For an EE only attribute, use `ee_attribute` instead.

```ruby
ee_attribute('best_service')
```

### Add service configuration to the settings template

We maintain a [global configuration template](../architecture/index.md#global-gitlab-configuration-template)
where examples of how to configure the services are available, commented out.

This file becomes the `/etc/gitlab/gitlab.rb` on fresh installs of the package.

Once you want to expose your service's configuration to users for them to change, add it
to this file. `files/gitlab-config-template/gitlab.rb.template`

```ruby
### Best Service configuration
# best_service['enable'] = true
# best_service['dir'] = '/var/opt/gitlab/best-service'
# best_service['log_directory'] = '/var/log/gitlab/best-service'
```

Use the underscore syntax here for word separation. The values provided are not
meant to reflect the defaults, but are to make it easier to uncomment to use the
service. If that isn't possible you can use values clearly meant to be replaced
like `YOURSECRET` etc. Or use the default when it makes the most sense.

## Include the service in the services list

In order to allow the service to be easily enable/disabled within the recipes, it
should be added to the [services list](../architecture/index.md#services)
and given appropriate groups.

In the `files/gitlab-cookbooks/package/libraries/config/services.rb` file, add the
service to the appropriate Config class, Base or EE depending on whether the
service is only for GitLab EE.

```ruby
service 'best_service', groups: ['bestest']
```

We use the underscore word separation because these services act on the Mash
objects we created earlier. Specifying groups makes it easier to disable/enable
multiple related services as once.

If none of the existing groups match with what your service does, and you don't
currently need to enable/disable the service using a group. Don't bother adding
at this time.

Some examples of existing groups you may want to use:

- If the service is enabled in omnibus be default, it should add the `DEFAULT_GROUP` group.
- If the service should really not be disabled in almost any scenario, add the `SYSTEM_GROUP`.
- If the service relies on GitLab Rails having been configured, add the `rails` group.
- If the service is a new Prometheus exporter, add the `prometheus` group.

## Create enable and disable recipes for the service

### Enable recipe

The enable recipe should be created as `files/gitlab-cookbooks/<cookbook-name>/recipes/<service-name>.rb`
if it being added to an existing cookbook. If the service has its own cookbook,
the enable recipe can be created as `files/gitlab-cookbooks/<cookbook-name>/recipes/enable.rb`.

In the recipe you will want to create the working directory in `/var/opt/gitlab`
for your service. You will want to ensure the system user that runs your service
is created. Render any configuration files needed for your service into your working
directory.

Near the end of the recipe you will want to make a call to the runit service definition
to define your recipe. In order for this work you will need to have created
a run file in the cookbooks `templates/default` directory. These filenames start
with `sv-` followed by the service name, followed by the runit action name.

A service typically needs a `run`, `log-run`, and `log-config`.

`sv-best-service-log-config.erb`:

```ruby
<%= "s#@svlogd_size" if @svlogd_size %>
<%= "n#@svlogd_num" if @svlogd_num %>
<%= "t#@svlogd_timeout" if @svlogd_timeout %>
<%= "!#@svlogd_filter" if @svlogd_filter %>
<%= "u#@svlogd_udp" if @svlogd_udp %>
<%= "p#@svlogd_prefix" if @svlogd_prefix %>
```

`sv-best-service-log-run.erb`:

```ruby
#!/bin/sh
exec svlogd -tt <%= @options[:log_directory] %>
```

`sv-best-service-run.erb`:

```ruby
#!/bin/sh
exec 2>&1
<%= render("mount_point_check.erb") %>
cd <%= node['gitlab']['best-service']['dir'] %>
exec chpst -P /opt/gitlab/embedded/bin/best-service -config-flags -etc
```

Depending on what you are running, and which user should run it, your run file
should be configured differently. Look in our other `-run.erb` for examples.

Within your recipe, the runit service should be called and started:

```ruby
runit_service "best-service" do
  options({
    configItem: 'value'
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['best-service'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start best-service" do
    retries 20
  end
end
```

### Disable recipe

The disable recipe should be created as `files/gitlab-cookbooks/<cookbook-name>/recipes/<service-name>_disable.rb`
if it being added to an existing cookbook. If the service has its own cookbook,
the disable recipe can be created as `files/gitlab-cookbooks/<cookbook-name>/recipes/disable.rb`.

The recipe needs to container any cleanup you want to do when you service is disabled,
and have a call to disable the runit service.

```ruby
runit_service "best-service" do
  action :disable
end
```

## Determine and document how log rotation will be handled

In Omnibus, [log rotation](https://docs.gitlab.com/ee/administration/logs.html#log-rotation) for
a given service can be handled by `logrotate`, `svlogd`, both or neither. The new service should
be included in the [log rotation](https://docs.gitlab.com/ee/administration/logs.html#log-rotation)
table with an indication about what is responsible for managing and rotating the logs for that
service. When adding a service to Omnibus GitLab, you should:

- Ensure that log rotation is in place for the new service.
- Open a merge request to have the new service added to
  [the log rotation table](https://docs.gitlab.com/ee/administration/logs.html#log-rotation).

If a new log is added that is not using `runit` (`svlogd`), the log must be manually
added to the logrotate configuration. The
[Improve logrotate handling](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6182) issue
has more information.

## Additional configuration parsing for the service

If you want to populate certain configuration options based on other options being set
by the user, we add a library for your service to parse variables.

The library should be added as `files/gitlab-cookbooks/<cookbook name>/libraries/<service-name>.rb`

The library should be a module named after your service that has a `parse_variables` method.

```ruby
module BestService
  class << self
    def parse_variables
      # setup some additional configuration based on the values of the user provided configuration
    end
  end
end
```

We then need to have the GitLab configuration call your parse_variables method.

Go into `files/gitlab-cookbooks/package/libraries/config/gitlab.rb` and update
your attribute to use the library.

```ruby
attribute('best_service').use { BestService }
```

Note that sequence for parsing variables matters. So if your library expects to
be parsed after another service's library, you need to update your attribute with
a `priority` value that comes later. (The default `priority` value is `20`)

```ruby
attribute('expected_service').use { ExpectedService }
attribute('best_service', sequence: 25).use { BestService }
```
