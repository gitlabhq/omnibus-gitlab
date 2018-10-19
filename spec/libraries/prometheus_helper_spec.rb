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

describe PrometheusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.new }
  subject { described_class.new(chef_run.node) }

  context 'version detection' do
    it 'detects version 1 correctly' do
      allow(File).to receive(:exist?).with(/var\/opt\/gitlab\/prometheus\/data/).and_return(true)

      expect(PrometheusHelper.is_version_1?("/var/opt/gitlab/prometheus")).to be_truthy
    end

    it 'detects version 2 correctly' do
      allow(File).to receive(:exist?).with(/var\/opt\/gitlab\/prometheus\/data/).and_return(false)

      expect(PrometheusHelper.is_version_1?("/var/opt/gitlab/prometheus")).to be_falsey
    end

    it 'returns binary and rule files correctly' do
      allow(PrometheusHelper).to receive(:is_version_1?).and_return(true)
      chef_run.node.set['gitlab']['prometheus']['home'] = '/var/opt/gitlab/prometheus'

      expect(subject.binary_and_rules).to eq(%w(prometheus1 rules.v1))
    end
  end

  context 'flags for prometheus' do
    context 'for version 1' do
      before { allow(PrometheusHelper).to receive(:is_version_1?).and_return(true) }

      context 'with default options' do
        it 'returns the correct default config string' do
          chef_run.converge('gitlab::default')
          expect(subject.flags('prometheus')).to eq(
            '-web.listen-address=localhost:9090 -storage.local.path=/var/opt/gitlab/prometheus/data -storage.local.chunk-encoding-version=2 -storage.local.target-heap-size=47689236 -config.file=/var/opt/gitlab/prometheus/prometheus.yml')
        end
      end

      context 'with custom options' do
        before { allow(Gitlab).to receive(:[]).and_call_original }

        it 'does not return the correct string if any attributes have been changed' do
          chef_run.node.set['gitlab']['prometheus']['home'] = '/fake/dir'
          chef_run.converge('gitlab::default')

          expect(subject.flags('prometheus')).to eq(
            '-web.listen-address=localhost:9090 -storage.local.path=/fake/dir/data -storage.local.chunk-encoding-version=2 -storage.local.target-heap-size=47689236 -config.file=/fake/dir/prometheus.yml')
        end
      end
    end

    context 'for version 2' do
      before { allow(PrometheusHelper).to receive(:is_version_1?).and_return(false) }

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
          chef_run.node.set['gitlab']['prometheus']['home'] = '/fake/dir'
          chef_run.converge('gitlab::default')

          expect(subject.flags('prometheus')).to eq(
            '--web.listen-address=localhost:9090 --storage.tsdb.path=/fake/dir/data --config.file=/fake/dir/prometheus.yml')
        end
      end
    end
  end
end
