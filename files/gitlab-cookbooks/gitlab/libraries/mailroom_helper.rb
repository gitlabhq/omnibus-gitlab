# frozen_string_literal: true

class MailroomHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def internal_api_url
    # The second returned value is for UNIX socket only.
    api_url, _ = WebServerHelper.internal_api_url(node)
    # In general, Ruby and most gems don't support HTTP request over Unix
    # socket. For internal API requests, we want to point the internal API
    # endpoint to workhorse to avoid round-trip through LB. Unfortunately, if
    # workhorse uses Unix socket, we have no choice except to point it at
    # the external URL.
    api_url = @node['gitlab']['gitlab-rails']['gitlab_url'] if api_url.start_with?("http+unix")
    api_url
  end
end
