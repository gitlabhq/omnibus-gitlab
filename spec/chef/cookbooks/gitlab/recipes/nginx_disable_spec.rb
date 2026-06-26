require 'chef_helper'

RSpec.describe 'gitlab::nginx_disable' do
  let(:chef_run) { converge_config('gitlab::nginx_disable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  # The recipe runs on every node where `gitlab_rails['enable']` is
  # false. That covers roles that never hosted rails configs
  # (Postgres, Patroni, monitoring). The converge is safe regardless
  # because each `nginx_configuration` `:delete` wraps Chef's
  # `file` `:delete`.
  it 'declares delete actions for the five rails-owned nginx configs' do
    expect(chef_run).to delete_nginx_configuration('gitlab-workhorse-upstream')
    expect(chef_run).to delete_nginx_configuration('rails')
    expect(chef_run).to delete_nginx_configuration('smartcard')
    expect(chef_run).to delete_nginx_configuration('health')
    expect(chef_run).to delete_nginx_configuration('rails-metrics')
  end
end
