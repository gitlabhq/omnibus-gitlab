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

  let(:template_path) { '/opt/gitlab/etc/gitlab-backup-cli-config.yml' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'creates gitlab-backup-cli-config.yml template' do
    expect(chef_run).to create_template(template_path).with(
      owner: 'root',
      group: 'root',
      mode: '0644',
      source: 'gitlab-backup-cli-config.yml.erb',
      sensitive: true
    )
  end
end
