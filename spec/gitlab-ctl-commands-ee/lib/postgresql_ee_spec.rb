require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')
$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands-ee/lib')

require 'postgresql_ee'

describe GitlabCtl::PostgreSQL do
  describe "#get_primary" do
    context 'when Consul disabled' do
      subject { GitlabCtl::PostgreSQL.new({}) }

      it 'should raise an error' do
        expect { subject.get_primary } .to raise_error(/Consul agent is not enabled/)
      end
    end

    context 'when PostgreSQL service name is not defined' do
      subject { GitlabCtl::PostgreSQL.new({ 'consul' => { 'enable' => true } }) }

      it 'should raise an error' do
        expect { subject.get_primary } .to raise_error(/PostgreSQL service name is not defined/)
      end
    end

    context 'when required settings are available' do
      subject do
        GitlabCtl::PostgreSQL.new(
          {
            'consul' => {
              'enable' => true,
              'internal' => {
                'postgresql_service_name' => 'fake'
              }
            }
          }
        )
      end

      before do
        allow_any_instance_of(Resolv::DNS).to receive(:getresources)
          .with('fake.service', Resolv::DNS::Resource::IN::SRV)
          .and_return([Struct.new(:target, :port).new('fake.address', 6432)])
        allow_any_instance_of(Resolv::DNS).to receive(:getaddress)
          .with('fake.address')
          .and_return('1.2.3.4')
      end

      it 'should get the list of PostgreSQL endpoints' do
        expect(subject.get_primary).to eq ['1.2.3.4:6432']
      end
    end
  end
end
