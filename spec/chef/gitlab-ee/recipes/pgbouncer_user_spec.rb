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

require 'chef_helper'

describe 'gitlab-ee::pgbouncer_user' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      {
        postgresql: {
          enable: true,
          pgbouncer_user: 'pgbouncer',
          pgbouncer_user_password: 'fakepassword'
        }
      }
    )
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:user_exists?).with('pgbouncer').and_return(false)
  end

  context 'inital run' do
    it 'should create the pgbouncer user' do
      expect(chef_run).to include_recipe('gitlab-ee::pgbouncer_user')
      expect(chef_run).to create_postgresql_user('pgbouncer')
    end

    it 'should create the pg_shadow_lookup function' do
      postgresql_user = chef_run.postgresql_user('pgbouncer')
      expect(postgresql_user).to notify('execute[Add pgbouncer auth function]')
    end
  end

  context 'function already exist' do
    it 'should not try and recreate the function' do
      allow_any_instance_of(PgHelper).to receive(:has_function?).with('gitlabhq_production', 'pg_shadow_lookup').and_return(true)
      expect(chef_run).not_to run_execute('Add pgbouncer auth function')
    end
  end

  context 'auth_query is not the default value' do
    before do
      stub_gitlab_rb(
        {
          pgbouncer: {
            auth_query: 'SELECT * FROM FAKETABLE'
          }
        }
      )
    end

    it 'should not create the pg_shadow_lookup function' do
      expect(chef_run).not_to run_execute('Add pgbouncer auth function')
    end
  end
end
