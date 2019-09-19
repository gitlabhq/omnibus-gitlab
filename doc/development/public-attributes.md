# Working with public_attributes.json

Chef stores a copy of a nodes attributes at the end of a reconfigure in `/opt/gitlab/embedded/nodes/$NODE_NAME.json`. Due to the sensitive nature of some of the attributes, it is only readable by the root user. To work around this, we've created a file (defaults to `/var/opt/gitlab/public_attributes.json`) which contains a set of attributes we've whitelisted for use of non-root services. This file is recreated on every run of `gitlab-ctl reconfigure`.

## Adding an entry to public_attributes.json

The `public_attributes.json` file is populated by merging the results of a call to the `public_attributes` method of a helper class. For example:

```ruby
class TestHelper < BaseHelper
  attr_accessor :node

  def public_attributes
    {
      'gitlab' => {
        'test' => node['gitlab']['test']
      }
    }
  end
end
```

The file is generated as part of the [GitLabHandler](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/package/libraries/handlers/gitlab.rb#L36).

## Reading an entry from public_attributes.json from a `gitlab-ctl` command

In order to access the public nodes, you should use the provided [`GitlabCtl::Util.get_public_node_attributes` method](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-ctl-commands/lib/gitlab_ctl/util.rb#L60)

```ruby
attributes = GitlabCtl::Util.get_public_node_attributes

puts attributes['gitlab']['test']
```
