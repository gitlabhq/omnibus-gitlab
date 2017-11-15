# Adding deprecation messages

As part of our [deprecation policy][] we may need to add
messages to `gitlab-ctl reconfigure` that advise the user of any deprecated
settings they are using.

To do this we should add code that detects the use of the old setting,
handles the value (for instance remapping it to a new setting), and notify the
user that they have something to do with `LoggingHelper.deprecation`.

Here's an example from the `nginx` cookbook:

~~~ruby
    def parse_nginx_listen_address
      return unless Gitlab['nginx']['listen_address']

      # The user specified a custom NGINX listen address with the legacy
      # listen_address option. We have to convert it to the new
      # listen_addresses setting.
      LoggingHelper.deprecation "nginx['listen_address'] is deprecated. Please use nginx['listen_addresses']"
      Gitlab['nginx']['listen_addresses'] = [Gitlab['nginx']['listen_address']]
    end
~~~

[deprecation policy]: https://docs.gitlab.com/omnibus/package-information/deprecation_policy.html
