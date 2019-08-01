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

require 'erb'
require 'etc'

require_relative '../../lib/gitlab_ctl'

module GitlabCtl
  class PostgreSQL
    class Pgpass
      attr_accessor :hostname, :port, :database, :username, :password, :host_user, :userinfo

      def initialize(options = {})
        @hostname = options[:hostname] || '*'
        @port = options[:port] || '*'
        @database = options[:database] || '*'
        @username = options[:username] || '*'
        @password = options[:password] || '*'
        @host_user = options[:host_user]
        @userinfo = GitlabCtl::Util.userinfo(host_user)
      end

      def pgpass_template
        "<%= hostname %>:<%= port %>:<%= database %>:<%= username %>:<%= password %>"
      end

      def render
        ERB.new(pgpass_template).result(binding)
      end

      def host_user
        @host_user || ENV['USER']
      end

      def filename
        "#{userinfo.dir}/.pgpass"
      end

      def write
        File.open(filename, 'w') do |file|
          file.puts render
          file.chown(userinfo.uid, userinfo.gid)
          file.chmod(0600)
        end
      end
    end
  end
end
