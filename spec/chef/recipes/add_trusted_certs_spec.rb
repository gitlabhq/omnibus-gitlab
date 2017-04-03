require 'chef_helper'

describe 'add_trusted_certs recipe' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:cert_helper) { CertificateHelper.new('/etc/gitlab/trusted-certs', '/opt/gitlab/embedded/ssl/certs', '/var/opt/gitlab') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'creates the certificate directories' do
    expect(chef_run).to create_directory('/opt/gitlab/embedded/ssl/certs').with(mode: '0755')
    expect(chef_run).to create_directory('/etc/gitlab/trusted-certs').with(mode: '0755')
  end

  it 'creates a readme file for the managed certificate directory' do
    expect(chef_run).to create_file('/opt/gitlab/embedded/ssl/certs/README').with(
      mode: '0644',
      content: /This directory is managed by omnibus\-gitlab/
    )
  end

  context 'when new trusted certificates have been added' do
    before do
      allow(cert_helper).to receive(:new_certificate_added?).and_return(true)
      allow(CertificateHelper).to receive(:new).and_return(cert_helper)
    end

    it 'attempts to link trusted certificates into our certificate chain' do
      expect(chef_run).to run_ruby_block('Move existing certs and link to /opt/gitlab/embedded/ssl/certs')
    end
  end

  context 'when there have been no changes to the trusted certificates directory' do
    before do
      allow(cert_helper).to receive(:new_certificate_added?).and_return(false)
      allow(CertificateHelper).to receive(:new).and_return(cert_helper)
    end

    it 'does not attempt to link trusted certificates into our certificate chain' do
      expect(chef_run).not_to run_ruby_block('Move existing certs and link to /opt/gitlab/embedded/ssl/certs')
    end
  end
end
