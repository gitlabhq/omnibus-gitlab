#
# Copyright:: Copyright (c) 2024 GitLab Inc.
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

RSpec.describe 'gitlab::gitlab-backup-cli' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['package']['install-dir'] = '/opt/gitlab'
    end
  end

  let(:chef_run) do
    chef_runner.converge('gitlab::default')
  end

  let(:config_path) { '/opt/gitlab/etc/gitlab-backup-cli-config.yml' }
  let(:context_path) { '/opt/gitlab/etc/gitlab-backup-context.yml' }

  context 'by default' do
    it 'does not run' do
      expect(chef_run).not_to include_recipe('gitlab::gitlab-backup-cli')
    end
  end

  context 'when enabled' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      stub_gitlab_rb(
        gitlab_backup_cli: {
          enable: true
        }
      )
    end

    it 'includes the recipe' do
      expect(chef_run).to include_recipe('gitlab::gitlab-backup-cli')
    end

    it 'creates gitlab-backup-context.yml template' do
      expect(chef_run).to create_template(context_path).with(
        owner: 'root',
        group: 'root',
        mode: '0644',
        source: 'gitlab-backup-context.yml.erb',
        sensitive: true
      )
    end

    it 'deletes gitlab-backup-cli-config.yml template' do
      expect(chef_run).to delete_template(config_path)
    end

    it 'creates a gitlab-backup user' do
      expect(chef_run).to create_account('GitLab Backup User').with(
        username: 'gitlab-backup',
        groupname: 'gitlab-backup',
        home: '/var/opt/gitlab/backups'
      )
    end

    it 'adds the gitlab-backup user to the appropriate groups' do
      %w[git gitlab-psql registry].each do |group|
        expect(chef_run).to manage_group(group).with(
          members: ['gitlab-backup'],
          append: true
        )
      end
    end
  end
end
