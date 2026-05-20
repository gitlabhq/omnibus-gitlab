# frozen_string_literal: true

require 'chef_helper'

RSpec.describe 'default directories' do
  # The directory resource for `node['postgresql']['dir']` is in
  # postgresql::enable, not postgresql::directory_locations (which
  # only sets node defaults for unix_socket_directory and home).
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-base::config', 'postgresql::enable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'postgresql directory' do
    context 'with default settings' do
      it 'creates postgresql directory' do
        expect(chef_run).to create_directory('/var/opt/gitlab/postgresql').with(
          owner: 'gitlab-psql',
          group: 'gitlab-psql',
          mode: '2775',
          recursive: true
        )
      end
    end

    context 'with custom settings' do
      before do
        stub_gitlab_rb(
          postgresql: {
            dir: '/mypgdir',
            home: '/mypghomedir'
          })
      end

      it 'creates postgresql directory with custom path' do
        expect(chef_run).to create_directory('/mypgdir').with(
          owner: 'gitlab-psql',
          group: 'gitlab-psql',
          mode: '2775',
          recursive: true
        )
      end
    end
  end
end
