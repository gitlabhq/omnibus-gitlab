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
      config_sections.each do |config_section|
        stub_gitlab_rb(
          gitlab_rails: {
            "#{config_section}_enabled".to_sym => true,
            "#{config_section}_inbox_method".to_sym => 'microsoft_graph',
            "#{config_section}_inbox_options".to_sym => inbox_options
          }
        )
      end
    end

    it 'renders gitlab.yml with the right data' do
      config_sections.each do |config_section|
        expect(gitlab_yml[:production][config_section][:inbox_method]).to eq('microsoft_graph')
        expect(gitlab_yml[:production][config_section][:inbox_options]).to eq(inbox_options)
      end
    end
  end

  shared_examples 'configured sidekiq delivery method' do
    let(:gitlab_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/gitlab.yml') }
    let(:gitlab_yml_file_content) { ChefSpec::Renderer.new(chef_run, gitlab_yml_template).content }
    let(:gitlab_yml) { YAML.safe_load(gitlab_yml_file_content, [], [], true, symbolize_names: true) }

    before do
      stub_gitlab_rb(
        gitlab_rails: config_sections.each_with_object({}) do |config_section, memo|
          memo.merge!(
            "#{config_section}_enabled".to_sym => true,
            "#{config_section}_delivery_method".to_sym => 'sidekiq'
          )
        end
      )
    end

    it 'renders gitlab.yml with the right data' do
      config_sections.each do |config_section|
        expect(gitlab_yml[:production][config_section][:delivery_method]).to eq('sidekiq')
      end
    end
  end

  shared_examples 'configured webhook delivery method' do
    let(:gitlab_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/gitlab.yml') }
    let(:gitlab_yml_file_content) { ChefSpec::Renderer.new(chef_run, gitlab_yml_template).content }
    let(:gitlab_yml) { YAML.safe_load(gitlab_yml_file_content, [], [], true, symbolize_names: true) }

    before do
      stub_gitlab_rb(
        external_url: 'http://localhost/gitlab/', # Mind the last "/" character
        gitlab_rails: config_sections.each_with_object({}) do |config_section, memo|
          memo.merge!(
            "#{config_section}_enabled".to_sym => true,
            "#{config_section}_delivery_method".to_sym => 'webhook'
          )
        end
      )
    end

    it 'renders gitlab.yml with the right data' do
      config_sections.each do |config_section|
        expect(gitlab_yml[:production][config_section][:delivery_method]).to eq('webhook')
        expect(gitlab_yml[:production][config_section][:secret_file]).to eq(".gitlab_#{config_section}_secret")
        expect(gitlab_yml[:production][config_section][:gitlab_url]).to eq("http://localhost/gitlab")
      end
    end

    it 'triggers notifications' do
      config_sections.each do |config_section|
        templatesymlink = chef_run.templatesymlink("Create a gitlab_#{config_section}_secret and create a symlink to Rails root")
        expect(templatesymlink).to notify('runit_service[mailroom]').to(:restart).delayed
      end
    end

    context 'auth token is not specified' do
      before do
        allow(SecretsHelper).to receive(:generate_base64).with(32).and_return("a" * 32)
      end

      it 'renders the correct node attribute with auto-generated auth token' do
        config_sections.each do |config_section|
          expect(chef_run).to create_templatesymlink("Create a gitlab_#{config_section}_secret and create a symlink to Rails root").with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          ).with_variables(
            a_hash_including(
              secret_token: "a" * 32
            )
          )
        end
      end
    end

    context 'auth token is set' do
      let(:auth_token) { SecureRandom.base64(32) }

      before do
        stub_gitlab_rb(
          external_url: 'http://localhost/gitlab/',
          gitlab_rails: config_sections.each_with_object({}) do |config_section, memo|
            memo.merge!(
              "#{config_section}_enabled".to_sym => true,
              "#{config_section}_delivery_method".to_sym => 'webhook',
              "#{config_section}_auth_token".to_sym => "#{auth_token}-#{config_section}"
            )
          end
        )
      end

      it 'renders the correct node attribute' do
        config_sections.each do |config_section|
          expect(chef_run).to create_templatesymlink("Create a gitlab_#{config_section}_secret and create a symlink to Rails root").with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          ).with_variables(
            a_hash_including(
              secret_token: "#{auth_token}-#{config_section}"
            )
          )
        end
      end
    end
  end

  describe 'when disabled' do
    it_behaves_like 'disabled runit service', 'mailroom'
  end

  describe 'when enabled' do
    context 'when only service_desk_email enabled' do
      let(:config_sections) { %i[service_desk_email] }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            service_desk_email_enabled: true
          }
        )
      end

      it_behaves_like 'enabled runit service', 'mailroom', 'root', 'root'
      it_behaves_like 'configured logrotate service', 'mailroom', 'git', 'git'
      it_behaves_like 'configured sidekiq delivery method'
    end

    context 'when both service_desk_email and incoming_email enabled' do
      let(:config_sections) { %i[incoming_email service_desk_email] }

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
      it_behaves_like 'configured sidekiq delivery method'
    end

    context 'default values' do
      let(:config_sections) { %i[incoming_email] }

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
      let(:config_sections) { %i[incoming_email] }

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

    context 'incoming email with Microsoft Graph' do
      let(:config_sections) { %i[incoming_email] }

      it_behaves_like 'renders Microsoft Graph config'
    end

    context 'Service Desk email with Microsoft Graph' do
      let(:config_sections) { %i[service_desk_email] }

      it_behaves_like 'renders Microsoft Graph config'
    end

    context 'Incoming Email webhook delivery method' do
      let(:config_sections) { %i[incoming_email] }

      it_behaves_like 'configured webhook delivery method'
    end

    context 'Service Desk Email webhook delivery method' do
      let(:config_sections) { %i[incoming_email] }

      it_behaves_like 'configured webhook delivery method'
    end

    context 'Both Incoming Email and Service Desk Email webhook delivery method' do
      let(:config_sections) { %i[incoming_email service_desk_email] }

      it_behaves_like 'configured webhook delivery method'
    end
  end

  context 'with specified exit_log_format' do
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
