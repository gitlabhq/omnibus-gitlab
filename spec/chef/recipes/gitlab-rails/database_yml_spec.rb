require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  describe 'Database settings' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }
    let(:database_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database.yml') }
    let(:database_yml_file_content) { ChefSpec::Renderer.new(chef_run, database_yml_template).content }
    let(:database_yml) { YAML.safe_load(database_yml_file_content, [], [], true, symbolize_names: true) }
    let(:default_content) do
      {
        main: {
          adapter: 'postgresql',
          application_name: nil,
          collation: nil,
          connect_timeout: nil,
          database: "gitlabhq_production",
          database_tasks: true,
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
      }
    end

    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow(File).to receive(:symlink?).and_call_original
    end

    context 'with default settings' do
      it 'renders database.yml with main database and default values' do
        expect(database_yml[:production]).to eq(default_content)
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
          expect(database_yml[:production][:main][:database_tasks]).to eq(true)
        end
      end

      context 'via top level db_* keys and overwritten main:' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              db_database: 'foobar',
              db_database_tasks: true,
              databases: {
                main: {
                  enable: true,
                  db_database_tasks: false
                }
              }
            }
          )
        end

        it 'renders database.yml with user specified values for main database' do
          expect(database_yml[:production][:main][:database]).to eq('foobar')
          expect(database_yml[:production][:main][:database_tasks]).to eq(false)
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
        context 'when using the same database as main:' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                databases: {
                  ci: {
                    enable: true
                  }
                }
              }
            )
          end

          it 'renders database.yml with main stanza first' do
            expect(database_yml_file_content).to match("production:\n  main:")
          end

          it 'renders database.yml with both main and additional databases using default values, but disabled database_tasks' do
            ci_content = default_content[:main].dup
            ci_content[:database_tasks] = false
            expected_output = default_content.merge(ci: ci_content)

            expect(database_yml[:production]).to eq(expected_output)
          end
        end

        context 'when using a different database to main:' do
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

          it 'renders database.yml with main stanza first' do
            expect(database_yml_file_content).to match("production:\n  main:")
          end

          it 'renders database.yml with both main and additional databases using default values, and enabled database_tasks' do
            ci_content = default_content[:main].dup
            ci_content[:database] = 'gitlabhq_production_ci'
            ci_content[:database_tasks] = true
            expected_output = default_content.merge(ci: ci_content)

            expect(database_yml[:production]).to eq(expected_output)
          end
        end

        context 'when db_database_tasks is explicitly enabled in main, but disabled in CI' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                databases: {
                  main: {
                    db_connect_timeout: 30,
                    db_database_tasks: true
                  },
                  ci: {
                    enable: true,
                    db_host: 'patroni-ci',
                    db_connect_timeout: 50,
                    db_database_tasks: false
                  }
                }
              }
            )
          end

          it 'renders database.yml with user specified DB settings' do
            expect(database_yml[:production][:main][:connect_timeout]).to eq(30)
            expect(database_yml[:production][:main][:database_tasks]).to eq(true)
            expect(database_yml[:production][:ci][:connect_timeout]).to eq(50)
            expect(database_yml[:production][:ci][:database_tasks]).to eq(false)
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
                    db_connect_timeout: 50,
                    db_database_tasks: false
                  }
                }
              }
            )
          end

          it 'renders database.yml with user specified DB settings' do
            expect(database_yml[:production][:main][:connect_timeout]).to eq(30)
            expect(database_yml[:production][:main][:database_tasks]).to eq(true)
            expect(database_yml[:production][:ci][:connect_timeout]).to eq(50)
            expect(database_yml[:production][:ci][:database_tasks]).to eq(false)
          end
        end

        context 'with additional database specified but not enabled' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                databases: {
                  main: {
                    db_connect_timeout: 30,
                  },
                  ci: {
                    db_connect_timeout: 50
                  }
                }
              }
            )
          end

          it 'renders database.yml without additional database' do
            expect(database_yml[:production].keys).not_to include('ci')
          end
        end

        context 'with invalid additional database specified' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                databases: {
                  foobar: {
                    enable: true,
                    db_database: 'gitlabhq_foobar'
                  },
                  johndoe: {
                    db_database: 'gitlabhq_johndoe'
                  },
                  ci: {
                    enable: true,
                    db_database: 'gitlabhq_ci'
                  }
                }
              }
            )
          end

          it 'raises warning about invalid database' do
            chef_run
            expect_logged_warning("Additional database `foobar` not supported in Rails application. It will be ignored.")
          end

          it 'does not raise warning about invalid database that is not enabled' do
            chef_run
            expect(LoggingHelper.messages).not_to include(kind: :warning, message: /Additional database `johndoe` not supported/)
          end
        end
      end
    end
  end
end
