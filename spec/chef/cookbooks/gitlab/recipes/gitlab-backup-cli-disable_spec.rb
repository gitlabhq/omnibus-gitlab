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

RSpec.describe 'gitlab::gitlab-backup-cli-disable' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['package']['install-dir'] = '/opt/gitlab'
    end
  end

  let(:chef_run) do
    chef_runner.converge('gitlab::default')
  end

  let(:template_path) { '/opt/gitlab/etc/gitlab-backup-cli-config.yml' }

  context 'by default' do
    it 'is included' do
      expect(chef_run).to include_recipe('gitlab::gitlab-backup-cli_disable')
    end

    it 'removes the gitlab-backup-cli-config.yml template' do
      expect(chef_run).to delete_template(template_path)
    end

    it 'removes the gitlab-backup user' do
      expect(chef_run).to remove_account('GitLab Backup User')
    end

    it 'removes the gitlab-backup user from the appropriate groups' do
      %w[git gitlab-psql registry].each do |group|
        expect(chef_run).to manage_group(group).with(
          excluded_members: ['gitlab-backup'],
          append: true
        )
      end
    end
  end
end
