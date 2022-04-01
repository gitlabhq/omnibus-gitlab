require 'chef_helper'

RSpec.describe 'gitlab-ee::geo-secondary_disable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default') }
  let(:database_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database.yml') }
  let(:database_yml_file_content) { ChefSpec::Renderer.new(chef_run, database_yml_template).content }
  let(:database_yml) { YAML.safe_load(database_yml_file_content, [], [], true, symbolize_names: true) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when geo_secondary_role is disabled' do
    before do
      stub_gitlab_rb(geo_secondary_role: { enable: false })
    end

    context 'database_geo.yml' do
      it 'removes the database_geo.yml symlink' do
        expect(chef_run).to delete_templatesymlink('Remove the deprecated database_geo.yml symlink')
                              .with(link_to: '/var/opt/gitlab/gitlab-rails/etc/database_geo.yml',
                                    link_from: '/opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml')
      end
    end

    context 'database.yml' do
      it 'renders database.yml without geo database' do
        expect(database_yml[:production].keys).not_to include(:geo)
      end

      context 'with geo database specified' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              databases: {
                geo: {
                  enable: true,
                  db_connect_timeout: 50
                }
              }
            }
          )
        end

        it 'renders database.yml without geo database' do
          expect(database_yml[:production].keys).not_to include(:geo)
        end
      end
    end
  end
end
