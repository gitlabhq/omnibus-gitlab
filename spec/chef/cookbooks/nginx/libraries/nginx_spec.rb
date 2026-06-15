require 'chef_helper'

RSpec.describe Nginx do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(LoggingHelper).to receive(:deprecation).and_return(true)
  end

  context 'by default' do
    it 'does not log deprecation message' do
      expect(LoggingHelper).not_to receive(:deprecation)

      described_class.translate_service_nginx_settings('pages', node_key: 'gitlab_pages')
      described_class.translate_service_nginx_settings('registry')
      described_class.translate_service_nginx_settings('gitlab_kas')
    end
  end

  context 'when registry nginx is specified' do
    before do
      stub_gitlab_rb(
        registry_nginx: {
          redirect_http_to_https: true
        }
      )
    end

    it 'translates the setting correctly' do
      described_class.translate_service_nginx_settings('registry')

      expect(Gitlab['registry']['nginx']).to match(hash_including(redirect_http_to_https: true))
    end

    it 'logs deprecation message' do
      expect(LoggingHelper).to receive(:deprecation).with("registry_nginx has been deprecated. Please use registry['nginx'] instead.")

      described_class.translate_service_nginx_settings('registry')
    end
  end

  context 'when pages_nginx is specified' do
    before do
      stub_gitlab_rb(
        pages_nginx: {
          redirect_http_to_https: true
        }
      )
    end

    it 'translates the setting correctly' do
      described_class.translate_service_nginx_settings('pages', node_key: 'gitlab_pages')

      expect(Gitlab['gitlab_pages']['nginx']).to match(hash_including(redirect_http_to_https: true))
    end

    it 'logs deprecation message' do
      expect(LoggingHelper).to receive(:deprecation).with("pages_nginx has been deprecated. Please use gitlab_pages['nginx'] instead.")

      described_class.translate_service_nginx_settings('pages', node_key: 'gitlab_pages')
    end
  end

  context 'when gitlab_kas_nginx is specified' do
    before do
      stub_gitlab_rb(
        gitlab_kas_nginx: {
          redirect_http_to_https: true
        }
      )
    end

    it 'translates the setting correctly' do
      described_class.translate_service_nginx_settings('gitlab_kas')

      expect(Gitlab['gitlab_kas']['nginx']).to match(hash_including(redirect_http_to_https: true))
    end

    it 'logs deprecation message' do
      expect(LoggingHelper).to receive(:deprecation).with("gitlab_kas_nginx has been deprecated. Please use gitlab_kas['nginx'] instead.")

      described_class.translate_service_nginx_settings('gitlab_kas')
    end
  end
end
