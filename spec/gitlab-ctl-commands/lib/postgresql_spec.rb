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

  describe '#postgresql_group' do
    before do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(
        {
          'postgresql' => {
            'group' => 'foo'
          }
        }
      )
    end

    it 'returns the correct group' do
      expect(described_class.postgresql_group).to eq('foo')
    end
  end

  describe '#postgresql_version' do
    context 'when PG_VERSION file exists' do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return('12\n')
      end

      it 'returns the version' do
        expect(described_class.postgresql_version('/var/opt/gitlab')).to eq(12)
      end
    end

    context 'when PG_VERSION file exists' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'returns nil' do
        expect(described_class.postgresql_version('/var/opt/gitlab')).to be_nil
      end
    end
  end
end
