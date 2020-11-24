class WebServerHelper
  class << self
    def enabled?
      Services.enabled?('puma') || Services.enabled?('unicorn')
    end

    def service_name
      # We are defaulting to Puma here if unicorn isn't explicitly enabled
      if Services.enabled?('unicorn')
        'unicorn'
      else
        'puma'
      end
    end

    def internal_api_url(node)
      workhorse_helper = GitlabWorkhorseHelper.new(node)

      gitlab_url = node['gitlab']['gitlab-rails']['internal_api_url']

      # If no internal_api_url is specified, default to Workhorse settings
      workhorse_url = node['gitlab']['gitlab-workhorse']['listen_addr']
      relative_path = Gitlab['gitlab_workhorse']['relative_url']
      gitlab_url ||= workhorse_helper.unix_socket? ? "http+unix://#{ERB::Util.url_encode(workhorse_url)}" : "http://#{workhorse_url}#{relative_path}"
      gitlab_relative_path = relative_path || '' if workhorse_helper.unix_socket?

      [gitlab_url, gitlab_relative_path]
    end
  end
end
