require 'spec_helper'
require 'omnibus-ctl'

RSpec.shared_context 'ctl' do
  let(:ctl) { Omnibus::Ctl.new('testing-ctl') }

  before do
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).and_call_original

    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      "/opt/testing-ctl/embedded/cookbooks/package/libraries/gitlab_cluster"
    ) do
      require_relative("../../../files/gitlab-cookbooks/package/libraries/gitlab_cluster")
    end

    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      "/opt/testing-ctl/embedded/service/omnibus-ctl-ee/lib/geo/#{command_script}"
    ) do
      require_relative("../../../files/gitlab-ctl-commands-ee/lib/geo/#{command_script}")
    end

    ctl.load_file("files/gitlab-ctl-commands-ee/#{command_script}.rb")
  end
end
