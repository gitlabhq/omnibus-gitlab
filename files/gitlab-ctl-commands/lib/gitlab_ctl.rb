#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require_relative 'gitlab_ctl/pg_upgrade'
require_relative 'gitlab_ctl/prometheus_upgrade'
require_relative 'gitlab_ctl/util'

module GitlabCtl
  class Errors
    class ExecutionError < StandardError
      attr_accessor :command, :stdout, :stderr

      def initialize(command, stdout, stderr)
        @command = command
        @stdout = stdout
        @stderr = stderr
      end
    end

    class NodeError < StandardError; end

    class PasswordMismatch < StandardError; end
  end
end
