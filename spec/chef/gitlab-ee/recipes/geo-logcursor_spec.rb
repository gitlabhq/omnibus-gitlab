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
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when disabled' do
    it_behaves_like 'disabled runit service', 'geo-logcursor'
  end

  describe 'when enabled' do
    before do
      stub_gitlab_rb(
        geo_logcursor: {
          enable: true,
        }
      )
    end

    it_behaves_like 'enabled runit service', 'geo-logcursor', 'root', 'root'
  end
end
