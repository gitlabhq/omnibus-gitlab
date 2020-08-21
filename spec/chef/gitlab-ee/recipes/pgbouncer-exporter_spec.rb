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
require 'chef_helper'

RSpec.describe 'gitlab-ee::pgbouncer-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:config_yaml) { '/var/opt/gitlab/pgbouncer-exporter/pgbouncer-exporter.yaml' }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when enabled' do
    before do
      stub_gitlab_rb(
        pgbouncer_exporter: {
          enable: true
        },
        pgbouncer: {
          enable: true,
          databases: {
            gitlabhq_production: {
              host: '1.2.3.4'
            }
          }
        },
        postgresql: {
          pgbouncer_user: 'fakeuser',
          pgbouncer_user_password: 'fakeuserpassword'
        }
      )
    end

    it 'includes the pgbouncer-exporter recipe' do
      expect(chef_run).to include_recipe('gitlab-ee::pgbouncer-exporter')
    end

    it 'includes the postgresql user recipe' do
      expect(chef_run).to include_recipe('postgresql::user')
    end

    it_behaves_like 'enabled runit service', 'pgbouncer-exporter', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/pgbouncer-exporter/env').with_variables(default_vars)
    end

    it 'creates the appropriate directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/pgbouncer-exporter')
    end
  end
end
