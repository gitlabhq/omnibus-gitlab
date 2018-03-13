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
  end

  context 'create the rails pgbouncer user' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      stub_gitlab_rb(
        {
          postgresql: {
            enable: true,
            pgbouncer_user: 'pgbouncer-rails',
            pgbouncer_user_password: 'fakepassword'
          }
        }
      )
    end

    it 'should call pgbouncer_user with the correct values for rails' do
      expect(chef_run).to create_pgbouncer_user('rails').with(
        database: 'gitlabhq_production',
        password: 'fakepassword',
        user: 'pgbouncer-rails',
        add_auth_function: true
      )
      expect(chef_run).not_to create_pgbouncer_user('geo')
    end
  end

  context 'auth_query is not the default value' do
    before do
      stub_gitlab_rb(
        {
          pgbouncer: {
            auth_query: 'SELECT * FROM FAKETABLE'
          },
          postgresql: {
            enable: true,
            pgbouncer_user: 'pgbouncer-rails',
            pgbouncer_user_password: 'fakepassword'
          }
        }
      )
    end

    it 'should not create the pg_shadow_lookup function' do
      expect(chef_run).to create_pgbouncer_user('rails').with(
        add_auth_function: false
      )
    end
  end

  context 'no pgbouncer user' do
    before do
      stub_gitlab_rb(
        {
          postgresql: {
            enable: true,
          },
          geo_postgresql: {
            enable: true,
          }
        }
      )
    end

    it 'should not create the pgbouncer user' do
      expect(chef_run).not_to create_pgbouncer_user('rails')
      expect(chef_run).not_to create_pgbouncer_user('geo')
    end
  end

  context 'create the geo pgbouncer user' do
    before do
      stub_gitlab_rb(
        {
          geo_postgresql: {
            enable: true,
            pgbouncer_user: 'pgbouncer-geo',
            pgbouncer_user_password: 'fakepassword'
          }
        }
      )
      allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:user_exists?).with('pgbouncer-geo').and_return(false)
    end

    it 'should call pgbouncer_user with the correct values for geo' do
      expect(chef_run).to create_pgbouncer_user('geo').with(
        database: 'gitlabhq_geo_production',
        password: 'fakepassword',
        user: 'pgbouncer-geo',
        add_auth_function: true
      )
      expect(chef_run).not_to create_pgbouncer_user('rails')
    end
  end
end
