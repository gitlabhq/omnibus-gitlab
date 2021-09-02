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

# ConfigMash is a custom Mash based on Chef::Node::ViviMash
# But it does not have the attribute and state tracking capabilities for use in a node
# and only auto-vivifies when used within a block passed to Gitlab::ConfigMash.auto_vivify
#
# @see Chef::Node::VividMash
# @see http://www.rubydoc.info/github/opscode/chef/Chef/Node/VividMash
module Gitlab
  class ConfigMash < Mash
    # Sets context to auto_vivify any ConfigMash access inside the block
    #
    # @yield block in which any access to the ConfigMash will be auto vivified
    def self.auto_vivify
      return unless block_given?

      begin
        @auto_vivify = true
        yield
      ensure
        @auto_vivify = false
      end
    end

    # Returns whether context is set to auto vivify access to the ConfigMash
    #
    # @return [Boolean] whether access will auto vivify
    def self.auto_vivify?
      @auto_vivify || false
    end

    # Access a value stored in the ConfigMash
    # When auto_vivify? is enable and the key does not exist it creates a new ConfigMash for that key
    #
    # @param [String] key
    # @return [Gitlab::ConfigMash, Object]
    def [](key)
      value = super

      if ConfigMash.auto_vivify? && !key?(key)
        value = self.class.new({})
        self[key] = value
      else
        value
      end
    end

    # Cast a Hash that is passed in to ConfigMash
    # this method is called from Mash.[]=
    #
    # @param [Gitlab::ConfigMash, Hash, Object] value
    # @return [Gitlab::ConfigMash, Array, Object] either a CofigMash when its a Hash or a ConfigMash or original value otherwise
    def convert_value(value)
      if value.class == ConfigMash
        value
      elsif value.class == Hash
        ConfigMash.new(value)
      else
        super
      end
    end

    # Sets a value o the ConfigMash based on accessing the keys in order
    #
    # @param [Array] keys
    # @param [Object] value
    def deep_set(*keys, value)
      Gitlab::ConfigMash.auto_vivify do
        if keys.length == 1
          self[keys.first] = value
        else
          *keys, last = *keys
          keys.inject(self, :[])[last] = value
        end
      end
    end
  end
end
