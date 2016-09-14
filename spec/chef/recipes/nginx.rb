require 'chef_helper'

describe 'gitlab::nginx' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::nginx') }

  before :each do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('node').and_return({
      'package' => {
        'install-dir' => "/opt/gitlab"
      }
    })

    # generate a random number to use as error code
    @code = rand(1000)
    @nginx_errors = {
      @code => {
        'title' => 'TEST TITLE',
        'header' => 'TEST HEADER',
        'message' => 'TEST MESSAGE'
      }
    }
    @http_conf = '/var/opt/gitlab/nginx/conf/gitlab-http.conf'
  end

  it 'creates a custom error_page entry when a custom error is defined' do
    allow(Gitlab).to receive(:[]).with('nginx').and_return({ 'custom_error_pages' => @nginx_errors})

    expect(chef_run).to render_file(@http_conf).with_content { |content|
      expect(content).to include("error_page #{@code} /#{@code}-custom.html;")
    }
  end

  it 'renders an error template when a custom error is defined' do
    chef_run.node.normal['gitlab']['nginx']['custom_error_pages'] = @nginx_errors
    chef_run.converge('gitlab::nginx')
    expect(chef_run).to render_file("/opt/gitlab/embedded/service/gitlab-rails/public/#{@code}-custom.html").with_content {|content|
      expect(content).to include("TEST MESSAGE")
    }
  end

  it 'creates a standard error_page entry when no custom error is defined' do
    expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-http.conf').with_content { |content|
      expect(content).to include("error_page 404 /404.html;")
    }
  end

  it 'enables the proxy_intercept_errors option when custom_error_pages is defined' do
    chef_run.node.normal['gitlab']['nginx']['custom_error_pages'] = @nginx_errors
    chef_run.converge('gitlab::nginx')
    expect(chef_run).to render_file(@http_conf).with_content { |content|
      expect(content).to include("proxy_intercept_errors on")
    }
  end

  it 'uses the default proxy_intercept_errors option when custom_error_pages is not defined' do
    expect(chef_run).to render_file(@http_conf).with_content { |content|
      expect(content).not_to include("proxy_intercept_errors")
    }
  end
end
