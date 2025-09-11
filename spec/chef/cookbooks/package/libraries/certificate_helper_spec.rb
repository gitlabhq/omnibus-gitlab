require 'spec_helper'
require 'chef_helper'

RSpec.describe CertificateHelper do
  subject(:mash) { described_class.new('/trust/', '/omni-cert/', '/user-dir/') }

  describe 'rehash' do
    shared_examples 'c_rehash fallback' do
      it 'falls back to c_rehash' do
        openssl_results = double(run_command: [], stdout: '', stderr: stderr, exitstatus: 0)
        expect(Mixlib::ShellOut)
          .to receive(:new)
          .with('openssl rehash /trust/', anything)
          .and_return(openssl_results).once

        c_rehash_results = double(run_command: [], exitstatus: 0)
        expect(Mixlib::ShellOut)
          .to receive(:new)
          .with('c_rehash rehash /trust/', anything)
          .and_return(c_rehash_results).once

        subject.rehash
      end
    end

    context 'invalid command' do
      let(:stderr) { 'Invalid command' }

      it_behaves_like 'c_rehash fallback'
    end

    context 'multiple certificates' do
      let(:stderr) { 'rehash: warning: skipping godaddy.crt, it does not contain exactly one certificate or CRL' }

      it_behaves_like 'c_rehash fallback'
    end
  end
end
