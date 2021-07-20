require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  describe 'Database settings' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }
    let(:database_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database.yml') }
    let(:database_yml_file_content) { ChefSpec::Renderer.new(chef_run, database_yml_template).content }
    let(:database_yml) { YAML.safe_load(database_yml_file_content, [], [], true, symbolize_names: true) }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow(File).to receive(:symlink?).and_call_original
    end

    context 'with default settings' do
      it 'renders database.yml with main database and default values' do
        expect(database_yml[:production]).to eq(
          main: {
            adapter: 'postgresql',
            application_name: nil,
            collation: nil,
            connect_timeout: nil,
            database: "gitlabhq_production",
            encoding: "unicode",
            host: "/var/opt/gitlab/postgresql",
            keepalives: nil,
            keepalives_count: nil,
            keepalives_idle: nil,
            keepalives_interval: nil,
            load_balancing: {
              hosts: []
            },
            password: nil,
            port: 5432,
            prepared_statements: false,
            socket: nil,
            sslca: nil,
            sslcompression: 0,
            sslmode: nil,
            sslrootcert: nil,
            statement_limit: 1000,
            tcp_user_timeout: nil,
            username: "gitlab",
            variables: {
              statement_timeout: nil
            }
          }
        )
      end
    end

    context 'with user provided settings' do
      context 'via top level db_* keys' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              db_database: 'foobar'
            }
          )
        end

        it 'renders database.yml with user specified values for main database' do
          expect(database_yml[:production][:main][:database]).to eq('foobar')
        end
      end

      context "for main database via gitlab_rails['databases']['main'] setting" do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              databases: {
                main: {
                  enable: true,
                  db_database: 'foobar'
                }
              }
            }
          )
        end

        it 'renders database.yml with user specified values for main database' do
          expect(database_yml[:production][:main][:database]).to eq('foobar')
        end
      end

      context 'with additional databases specified' do
        context 'with default values for other settings' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                databases: {
                  ci: {
                    enable: true,
                    db_database: 'gitlabhq_production_ci'
                  }
                }
              }
            )
          end

          it 'renders database.yml with both main database and additional databses using default values' do
            expect(database_yml[:production]).to eq(
              main: {
                adapter: 'postgresql',
                application_name: nil,
                collation: nil,
                connect_timeout: nil,
                database: "gitlabhq_production",
                encoding: "unicode",
                host: "/var/opt/gitlab/postgresql",
                keepalives: nil,
                keepalives_count: nil,
                keepalives_idle: nil,
                keepalives_interval: nil,
                load_balancing: {
                  hosts: []
                },
                password: nil,
                port: 5432,
                prepared_statements: false,
                socket: nil,
                sslca: nil,
                sslcompression: 0,
                sslmode: nil,
                sslrootcert: nil,
                statement_limit: 1000,
                tcp_user_timeout: nil,
                username: "gitlab",
                variables: {
                  statement_timeout: nil
                }
              },
              ci: {
                adapter: 'postgresql',
                application_name: nil,
                collation: nil,
                connect_timeout: nil,
                database: "gitlabhq_production_ci",
                encoding: "unicode",
                host: "/var/opt/gitlab/postgresql",
                keepalives: nil,
                keepalives_count: nil,
                keepalives_idle: nil,
                keepalives_interval: nil,
                load_balancing: {
                  hosts: []
                },
                password: nil,
                port: 5432,
                prepared_statements: false,
                socket: nil,
                sslca: nil,
                sslcompression: 0,
                sslmode: nil,
                sslrootcert: nil,
                statement_limit: 1000,
                tcp_user_timeout: nil,
                username: "gitlab",
                variables: {
                  statement_timeout: nil
                },
                migrations_paths: 'db/ci_migrate'
              }
            )
          end
        end

        context 'with different settings for main database and additional databases' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                databases: {
                  main: {
                    db_connect_timeout: 30,
                  },
                  ci: {
                    enable: true,
                    db_connect_timeout: 50
                  }
                }
              }
            )
          end

          it 'renders database.yml with user specified DB settings' do
            expect(database_yml[:production][:main][:connect_timeout]).to eq(30)
            expect(database_yml[:production][:ci][:connect_timeout]).to eq(50)
          end
        end
      end
    end
  end
end
