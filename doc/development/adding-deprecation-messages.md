# Adding deprecation messages

We store a list of deprecations associated with it in the `list` method of
[`Gitlab::Deprecations` class](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/package/libraries/deprecations.rb)
If a configuration has to be deprecated, it has to be added to that list with
proper details.

Note: The process described below will become obsolete soon, with our new
deprecation management logic.

As part of our [deprecation policy][] we may need to add
messages to `gitlab-ctl reconfigure` that advise the user of any deprecated
settings they are using.

To do this we should add code that detects the use of the old setting,
handles the value (for instance remapping it to a new setting), and notify the
user that they have something to do with `LoggingHelper.deprecation`.

Here's an example from the `nginx` cookbook:

```ruby
    def parse_nginx_listen_address
      return unless Gitlab['nginx']['listen_address']

      # The user specified a custom NGINX listen address with the legacy
      # listen_address option. We have to convert it to the new
      # listen_addresses setting.
      LoggingHelper.deprecation "nginx['listen_address'] is deprecated. Please use nginx['listen_addresses']"
      Gitlab['nginx']['listen_addresses'] = [Gitlab['nginx']['listen_address']]
    end
```

If we need to print Ruby objects, we can make use of the [`print_ruby_object`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/package/libraries/helpers/output_helper.rb#L8-10) helper method. This needs `OutputHelper` class to be
included in your code. Take a look at [Gitaly library](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitaly/libraries/gitaly.rb)
for an example.

[deprecation policy]: https://docs.gitlab.com/omnibus/package-information/deprecation_policy.html
