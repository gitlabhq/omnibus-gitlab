require 'chef_helper'

RSpec.describe 'gitlab-ee::geo-secondary_disable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default') }
  let(:database_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database.yml') }
  let(:database_yml_file_content) { ChefSpec::Renderer.new(chef_run, database_yml_template).content }
  let(:database_yml) { YAML.safe_load(database_yml_file_content, aliases: true, symbolize_names: true) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when geo_secondary_role is disabled' do
    before do
      stub_gitlab_rb(geo_secondary_role: { enable: false })
    end

    context 'database.yml' do
      shared_examples 'removes Geo database settings' do
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

      context 'when gitlab_rails is enabled' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              enable: true
            }
          )
        end

        include_examples "removes Geo database settings"
      end

      context 'when geo-logcursor is enabled' do
        before do
          stub_gitlab_rb(
            geo_logcursor: {
              enable: true
            }
          )
        end

        include_examples "removes Geo database settings"
      end

      context 'when gitlab_rails and geo-logcursor are disabled' do
        before do
          stub_gitlab_rb(geo_postgresql: { enable: true },
                         gitlab_rails: { enable: false },
                         geo_logcursor: { enable: false })
        end

        it 'does not render the database.yml file' do
          expect(chef_run).not_to create_templatesymlink('Removes the geo database settings from database.yml and create a symlink to Rails root')
        end
      end
    end
  end
end
