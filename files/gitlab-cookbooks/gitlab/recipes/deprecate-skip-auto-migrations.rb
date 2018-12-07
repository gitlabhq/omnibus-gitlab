#
# Copyright:: Copyright (c) 2018 GitLab.com
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

file "/etc/gitlab/skip-auto-reconfigure" do
  only_if { File.exist?('/etc/gitlab/skip-auto-migrations') }
end

ruby_block 'skip-auto-migrations deprecation' do
  block do
    message = <<~MESSAGE
      Old file /etc/gitlab/skip-auto-migrations found.
      This file will stop being checked in GitLab 12, use /etc/gitlab/skip-auto-reconfigure
      instead.  This file has been automatically created for you as a migration aid.

      To disable this message, remove the deprecated /etc/gitlab/skip-auto-migrations
    MESSAGE
    LoggingHelper.deprecation(message)
  end

  only_if { File.exist?('/etc/gitlab/skip-auto-migrations') }
end
