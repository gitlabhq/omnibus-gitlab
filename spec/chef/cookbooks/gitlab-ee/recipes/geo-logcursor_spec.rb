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

RSpec.describe 'gitlab-ee::geo-logcursor' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-base::config', 'gitlab-ee::geo-logcursor') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when disabled' do
    # Converge the disable recipe directly; pre-apply the
    # RunitService#enabled? stub that the 'disabled runit service'
    # shared example sets inside an `it`.
    let(:chef_run) do
      ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-base::config', 'gitlab-ee::geo-logcursor_disable')
    end

    before do
      allow_any_instance_of(Chef::Provider::RunitService).to receive(:enabled?).and_return(true)
    end

    it_behaves_like 'disabled runit service', 'geo-logcursor'
  end

  describe 'when enabled' do
    context 'with default settings' do
      before do
        stub_gitlab_rb(
          geo_logcursor: {
            enable: true,
          }
        )
      end

      it_behaves_like 'enabled runit service', 'geo-logcursor', 'root', 'root'
    end

    context 'with user specified settings' do
      before do
        stub_gitlab_rb(
          geo_logcursor: {
            enable: true,
          },
          user: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like 'enabled runit service', 'geo-logcursor', 'root', 'root', 'foo', 'bar'
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      before do
        stub_gitlab_rb(geo_logcursor: { enable: true })
      end
      it_behaves_like 'enabled logged service', 'geo-logcursor', true, { log_directory_owner: 'git' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          geo_logcursor: {
            enable: true,
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'enabled logged service', 'geo-logcursor', true, { log_directory_owner: 'git', log_group: 'fugee' }
    end
  end
end
