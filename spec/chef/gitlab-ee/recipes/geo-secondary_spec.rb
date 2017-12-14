require 'chef_helper'

describe 'gitlab-ee::geo-secondary' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when geo-postgresql is disabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before { stub_gitlab_rb(geo_postgresql: { enable: false }) }

    it 'does not render the geo-secondary files' do
      expect(chef_run).not_to render_file('/opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml')
      expect(chef_run).not_to render_file('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml')
    end
  end

  context 'when geo-postgresql is enabled' do
    before do
      stub_gitlab_rb(geo_postgresql: { enable: true })

      %w(
        gitlab-monitor
        gitlab-workhorse
        logrotate
        nginx
        node-exporter
        postgres-exporter
        postgresql
        prometheus
        redis
        redis-exporter
        sidekiq
        unicorn
        gitaly
        geo-postgresql
      ).map { |svc| stub_should_notify?(svc, true) }
    end

    describe 'database.yml' do
      let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default') }

      let(:templatesymlink_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml') }
      let(:templatesymlink_link) { chef_run.link('Link /opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml to /var/opt/gitlab/gitlab-rails/etc/database_geo.yml') }

      it 'creates the template' do
        expect(chef_run).to create_template('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml').with(
          owner: 'root',
          group: 'root',
          mode: '0644'
        )
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml').with_content(/host: \"\/var\/opt\/gitlab\/geo-postgresql\"/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml').with_content(/database: gitlabhq_geo_production/)
      end

      it 'template triggers notifications' do
        expect(templatesymlink_template).to notify('service[unicorn]').to(:restart).delayed
        expect(templatesymlink_template).to notify('service[sidekiq]').to(:restart).delayed
      end
    end

    describe 'include_recipe' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'includes the Geo tracking DB recipe' do
        expect(chef_run).to include_recipe('gitlab-ee::geo-postgresql')
      end
    end

    describe 'migrations' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'runs the migrations' do
        expect(chef_run).to run_bash('migrate gitlab-geo tracking database')
      end
    end
  end

  context 'unicorn worker_processes' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.automatic['cpu']['total'] = 16
        node.automatic['memory']['total'] = '8388608KB' # 8GB
      end.converge('gitlab-ee::default')
    end

    it 'reduces the number of unicorn workers on secondary node' do
      stub_gitlab_rb(geo_secondary_role: { enable: true })

      expect(chef_run.node['gitlab']['unicorn']['worker_processes']).to eq 14
    end

    it 'does not reduce the number of unicorn workers on primary node' do
      stub_gitlab_rb(geo_primary_role: { enable: true })

      expect(chef_run.node['gitlab']['unicorn']['worker_processes']).to eq 17
    end
  end
end
