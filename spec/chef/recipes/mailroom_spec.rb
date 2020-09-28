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

RSpec.describe 'gitlab::mailroom' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when disabled' do
    it_behaves_like 'disabled runit service', 'mailroom'
  end

  describe 'when enabled' do
    context 'when only service_desk_email enabled' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            service_desk_email_enabled: true
          }
        )
      end

      it_behaves_like 'enabled runit service', 'mailroom', 'root', 'root'
    end

    context 'when both service_desk_email and incoming_email enabled' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            incoming_email_enabled: true,
            service_desk_email_enabled: true
          }
        )
      end

      it_behaves_like 'enabled runit service', 'mailroom', 'root', 'root'
    end

    context 'default values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            incoming_email_enabled: true
          }
        )
      end

      it_behaves_like 'enabled runit service', 'mailroom', 'root', 'root'

      it 'uses --log-exit-as plain' do
        expect(chef_run).to render_file("/opt/gitlab/sv/mailroom/run").with_content(/\-\-log\-exit\-as plain/)
      end
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            incoming_email_enabled: true
          },
          user: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like 'enabled runit service', 'mailroom', 'root', 'root'
    end
  end

  context 'with specified command line values' do
    before do
      stub_gitlab_rb(
        gitlab_rails: {
          incoming_email_enabled: true
        },
        mailroom: {
          exit_log_format: "json"
        }
      )
    end

    it 'correctly passes the --log-exit-as ' do
      expect(chef_run).to render_file("/opt/gitlab/sv/mailroom/run").with_content(/\-\-log\-exit\-as json/)
    end

    it_behaves_like 'enabled runit service', 'mailroom', 'root', 'root'
  end
end
