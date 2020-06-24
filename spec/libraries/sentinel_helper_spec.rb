require 'chef_helper'

describe SentinelHelper do
  let(:chef_run) { converge_config(is_ee: true) }
  subject { described_class.new(chef_run.node) }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  context '#myid' do
    context 'when retrieving from config' do
      it 'fails when myid is not 40 hex-characters long' do
        stub_gitlab_rb(
          sentinel: {
            myid: 'wrongid'
          }
        )

        expect { subject.myid }.to raise_error RuntimeError
      end

      it 'works when myid is 40 hex-characters long' do
        stub_gitlab_rb(
          sentinel: {
            myid: '1234567890abcdef1234567890abcdef12345678'
          }
        )

        expect { subject.myid }.not_to raise_error
      end
    end

    context 'when no config is defined' do
      let(:myid) { 'abcdef1234567890abcdef1234567890abcdef1' }

      it 'generates a random myid' do
        expect(subject.myid).not_to be_empty
      end

      it 'persist generated value into JSON file' do
        allow(subject).to receive(:generate_myid).at_least(:once) { myid }

        expect(subject).to receive(:save_to_file).with({ 'myid' => myid })
        subject.myid
      end
    end
  end
end
