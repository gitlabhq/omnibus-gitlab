require 'spec_helper'
require 'chef_helper'

RSpec.describe CertificateHelper do
  subject(:mash) { described_class.new('/trust/', '/omni-cert/', '/user-dir/') }

  describe 'rehash' do
    context 'if openssl rehash fails' do
      it 'falls back to c_rehash' do
        openssl_results = double(run_command: [], stdout: '', stderr: 'Invalid command', exitstatus: 0)
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
  end
end
