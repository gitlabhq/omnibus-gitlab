#
# Copyright:: Copyright (c) 2017 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'chef/mash'

# ConfigMash is a custom Mash based on http://www.rubydoc.info/github/opscode/chef/Chef/Node/VividMash
# But it does not have the attribute and state tracking capabilities for use in a node
# And only auto-vivifies when used within a block passed to ConfigMash.auto_vivify
module Gitlab
  class ConfigMash < Mash
    def self.auto_vivify
      return unless block_given?

      begin
        @auto_vivify = true
        yield
      ensure
        @auto_vivify = false
      end
    end

    def self.auto_vivify?
      @auto_vivify || false
    end

    def [](key)
      # Create a new mash when auto_vivify is enabled and the key does not exist
      value = super
      if ConfigMash.auto_vivify? && !key?(key)
        value = self.class.new({})
        self[key] = value
      else
        value
      end
    end

    def convert_value(value)
      # Cast a Hash that is passed in to ConfigMash
      # this method is called from Mash.[]=
      if value.class == ConfigMash
        value
      elsif value.class == Hash
        ConfigMash.new(value)
      else
        super
      end
    end
  end
end
