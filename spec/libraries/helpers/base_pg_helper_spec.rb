require 'chef_helper'

describe BasePgHelper do
  let(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(subject).to receive(:service_name) { 'postgresql' }
    allow(subject).to receive(:service_cmd) { 'gitlab-psql' }
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
