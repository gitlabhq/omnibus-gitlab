require 'spec_helper'
require 'gitlab/takeoff_helper'

describe TakeoffHelper  do
  let(:internal_client) { spy('Gitlab::Client') }
  subject(:service) { described_class.new('gstg', 'token', 'master') }
  before do
    allow(service).to_receive(:client).and_return(internal_client)
  end
  describe '#trigger_deploy' do
    it 'triggers an auto deploy' do
      puts "test"
    end
  end
end
