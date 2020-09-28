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

RSpec.describe PrometheusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.new }
  subject { described_class.new(chef_run.node) }

  context 'flags for prometheus' do
    context 'with default options' do
      it 'returns the correct default config string' do
        chef_run.converge('gitlab::default')
        expect(subject.flags('prometheus')).to eq(
          '--web.listen-address=localhost:9090 --storage.tsdb.path=/var/opt/gitlab/prometheus/data --config.file=/var/opt/gitlab/prometheus/prometheus.yml')
      end
    end

    context 'with custom options' do
      before { allow(Gitlab).to receive(:[]).and_call_original }

      it 'does not return the correct string if any attributes have been changed' do
        chef_run.node.normal['monitoring']['prometheus']['home'] = '/fake/dir'
        chef_run.converge('gitlab::default')

        expect(subject.flags('prometheus')).to eq(
          '--web.listen-address=localhost:9090 --storage.tsdb.path=/fake/dir/data --config.file=/fake/dir/prometheus.yml')
      end
    end
  end
end
