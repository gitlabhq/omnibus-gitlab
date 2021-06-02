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
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service templatesymlink)).converge('gitlab::default') }

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
      it_behaves_like 'configured logrotate service', 'mailroom', 'git', 'git'
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
      it_behaves_like 'configured logrotate service', 'mailroom', 'git', 'git'
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
      it_behaves_like 'configured logrotate service', 'mailroom', 'git', 'git'

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
      it_behaves_like 'configured logrotate service', 'mailroom', 'foo', 'bar'
    end

    shared_examples 'renders Microsoft Graph config' do
      let(:gitlab_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/gitlab.yml') }
      let(:gitlab_yml_file_content) { ChefSpec::Renderer.new(chef_run, gitlab_yml_template).content }
      let(:gitlab_yml) { YAML.safe_load(gitlab_yml_file_content, [], [], true, symbolize_names: true) }
      let(:inbox_options) do
        {
          tenant_id: 'MY-TENANT-ID',
          client_id: '12345',
          client_secret: 'MY-CLIENT-SECRET'
        }
      end

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            "#{config_section}_enabled".to_sym => true,
            "#{config_section}_inbox_method".to_sym => 'microsoft_graph',
            "#{config_section}_inbox_options".to_sym => inbox_options
          }
        )
      end

      it 'renders gitlab.yml with the right data' do
        expect(gitlab_yml[:production][config_section][:inbox_method]).to eq('microsoft_graph')
        expect(gitlab_yml[:production][config_section][:inbox_options]).to eq(inbox_options)
      end
    end

    context 'incoming email with Microsoft Graph' do
      let(:config_section) { :incoming_email }

      it_behaves_like 'renders Microsoft Graph config'
    end

    context 'Service Desk email with Microsoft Graph' do
      let(:config_section) { :service_desk_email }

      it_behaves_like 'renders Microsoft Graph config'
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
    it_behaves_like 'configured logrotate service', 'mailroom', 'git', 'git'
  end
end
