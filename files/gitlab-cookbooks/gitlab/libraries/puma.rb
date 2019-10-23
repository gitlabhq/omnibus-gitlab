#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

module Puma
  class << self
    def parse_variables
      only_one_allowed!
    end

    def only_one_allowed!
      return unless Services.enabled?('unicorn') && Services.enabled?('puma')

      raise 'Only one web server (Puma or Unicorn) can be enabled at the same time!'
    end
  end
end
