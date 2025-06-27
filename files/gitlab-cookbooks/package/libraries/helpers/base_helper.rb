#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

class BaseHelper
  def initialize(node)
    @node = node
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

  # Returns the attributes this helper wants to be made public.  Implement in your subclass.
  #
  # @return [Hash] the attributes that this helper wants to make public
  def public_attributes
    {}
  end
end
