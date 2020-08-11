require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'postgresql'

RSpec.describe GitlabCtl::PostgreSQL do
  describe "#postgresql_usernamename" do
    context 'when using legacy configuration' do
      before do
        allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(
          {
            'gitlab' => {
              'postgresql' => {
                'username' => 'foo'
              }
            }
          }
        )
      end
      it 'detects username correctly' do
        expect(described_class.postgresql_username).to eq('foo')
      end
    end

    context 'when using new configuration' do
      before do
        allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(
          {
            'postgresql' => {
              'username' => 'bar'
            }
          }
        )
      end
      it 'detects username correctly' do
        expect(described_class.postgresql_username).to eq('bar')
      end
    end
  end
end
