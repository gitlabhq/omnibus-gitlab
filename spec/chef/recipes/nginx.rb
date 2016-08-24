require 'chef_helper'

describe 'gitlab::nginx' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::nginx') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  it 'creates a custom error_page entry when a custom error is defined' do
    # generate a random number to use as error code
    code = rand(1000)
    chef_run.node.normal['gitlab']['nginx']['errors'] = {
      code => {
        'title' => 'TEST TITLE',
        'header' => 'TEST HEADER',
        'message' => 'TEST MESSAGE'
      }
    }
    chef_run.converge('gitlab::nginx')
    expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-http.conf').with_content { |content|
      expect(content).to include("error_page #{code} /#{code}-custom.html;")
    }
    expect(chef_run).to render_file("/opt/gitlab/embedded/service/gitlab-rails/public/#{code}-custom.html").with_content {|content|
      expect(content).to include("TEST MESSAGE")
    }
  end

  it 'creates a standard error_page entry when no custom error is defined' do
    chef_run.node.normal['nginx']['errors'] = nil
    chef_run.converge('gitlab::nginx')
    expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-http.conf').with_content { |content|
      expect(content).to include("error_page 404 /404.html;")
    }
  end
end
