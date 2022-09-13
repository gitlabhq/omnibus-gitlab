require 'chef_helper'

RSpec.describe WatchHelper::WatcherConfig do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  let(:standard_watcher_names) { ['postgresql'] }

  context 'when initialized' do
    it 'should have standard watchers defined' do
      expect(subject.standard_watchers.map(&:name)).to match_array(standard_watcher_names)
    end
  end
end
