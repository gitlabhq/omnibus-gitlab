require 'chef_helper'

describe BasePgHelper do
  let(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(subject).to receive(:service_name) { 'postgresql' }
    allow(subject).to receive(:service_cmd) { 'gitlab-psql' }
  end

  describe '#user_options' do
    before do
      result = spy('shellout')
      allow(result).to receive(:stdout).and_return("f|f|t|f\n")
      allow(subject).to receive(:do_shell_out).and_return(result)
    end

    it 'returns hash from query' do
      expect(subject.user_options('')).to eq(
        {
          'SUPERUSER' => false,
          'CREATEDB' => false,
          'REPLICATION' => true,
          'BYPASSRLS' => false
        }
      )
    end
  end

  describe '#user_options_set?' do
    let(:default_options) do
      {
        'SUPERUSER' => false,
        'CREATEDB' => false,
        'REPLICATION' => true,
        'BYPASSRLS' => false
      }
    end

    context 'default user options' do
      before do
        allow(subject).to receive(:user_options).and_return(default_options)
      end

      it 'returns true when no options are asked about' do
        expect(subject.user_options_set?('', [])).to be_truthy
      end

      it 'returns true when options are set to their defaults' do
        expect(subject.user_options_set?('', ['NOSUPERUSER'])).to be_truthy
      end

      it 'returns false when options are set away from their defaults' do
        expect(subject.user_options_set?('', ['SUPERUSER'])).to be_falsey
      end
    end

    context 'modified user' do
      before do
        allow(subject).to receive(:user_options).and_return(default_options.merge({ 'SUPERUSER' => true }))
      end

      it 'returns false when options is not what we expect' do
        expect(subject.user_options_set?('', ['NOSUPERUSER'])).to be_falsey
      end
    end
  end

  describe '#user_password_match?' do
    before do
      # user: gitlab pass: test123
      allow(subject).to receive(:user_hashed_password) { 'md5b56573ef0d94cff111898c63ec259f3f' }
    end

    it 'returns true when same password is in plain-text' do
      expect(subject.user_password_match?('gitlab', 'test123')).to be_truthy
    end

    it 'returns true when same password is in MD5 format' do
      expect(subject.user_password_match?('gitlab', 'md5b56573ef0d94cff111898c63ec259f3f')).to be_truthy
    end

    it 'returns false when wrong password is in plain-text' do
      expect(subject.user_password_match?('gitlab', 'wrong')).to be_falsey
    end

    it 'returns false when wrong password is in MD5 format' do
      expect(subject.user_password_match?('gitlab', 'md5b599de4332636c03a60fca13be1edb5f')).to be_falsey
    end
  end
end
