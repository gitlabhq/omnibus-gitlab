# By default, Chef's bash resource prints out the environment variables
# upon failure, but the environment may contain sensitive information. This
# resource suppresses that output.

require 'chef/resource'
require 'chef/resource/script'

class Chef
  class Resource
    class BashHideEnv < Chef::Resource::Bash
      provides :bash_hide_env

      property :environment, Hash, sensitive: true,
                                   description: "A Hash of environment variables in the form of `({'ENV_VARIABLE' => 'VALUE'})`. **Note**: These variables must exist for a command to be run successfully."
    end
  end
end

Chef::Provider::Script.provides(:bash_hide_env)
