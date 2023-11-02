require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  describe 'ClickHouse database settings' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }
    let(:clickhouse_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/click_house.yml') }
    let(:clickhouse_yml_file_content) { ChefSpec::Renderer.new(chef_run, clickhouse_yml_template).content }
    let(:clickhouse_yml) { YAML.safe_load(clickhouse_yml_file_content, aliases: true, symbolize_names: true) }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow(File).to receive(:symlink?).and_call_original
    end

    context 'with default settings' do
      it 'renders empty clickhouse.yml' do
        expect(clickhouse_yml[:production]).to eq(nil)
      end
    end

    context 'with databases setup' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            clickhouse_databases: {
              main: {
                database: 'production',
                url: 'https://example.com/path',
                username: 'gitlab',
                password: 'password'
              },
              main2: {
                database: 'production2',
                url: 'https://example.com/path2',
                username: 'gitlab2',
                password: 'password2'
              }
            }
          }
        )
      end

      it 'renders clickhouse.yml using these settings' do
        expect(clickhouse_yml[:production]).to eq(
          {
            main: {
              database: 'production',
              url: 'https://example.com/path',
              username: 'gitlab',
              password: 'password',
              variables: {
                enable_http_compression: 1,
                date_time_input_format: "basic"
              }
            },
            main2: {
              database: 'production2',
              url: 'https://example.com/path2',
              username: 'gitlab2',
              password: 'password2',
              variables: {
                enable_http_compression: 1,
                date_time_input_format: "basic"
              }
            }
          }
        )
      end
    end
  end
end
