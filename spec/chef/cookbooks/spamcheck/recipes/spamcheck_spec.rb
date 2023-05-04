require 'chef_helper'
require 'toml-rb'

RSpec.describe 'spamcheck' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when spamcheck is disabled (default)' do
    it 'includes spamcheck::disable recipe' do
      expect(chef_run).to include_recipe('spamcheck::disable')
    end
  end

  context 'when spamcheck is enabled' do
    before do
      stub_gitlab_rb(
        spamcheck: {
          enable: true
        }
      )
    end

    it 'includes spamcheck::enable recipe' do
      expect(chef_run).to include_recipe('spamcheck::enable')
    end
  end

  describe 'spamcheck::enable' do
    context 'with default values' do
      before do
        stub_gitlab_rb(
          spamcheck: {
            enable: true
          }
        )
      end

      it 'creates config.toml with default values' do
        actual_content = get_rendered_toml(chef_run, '/var/opt/gitlab/spamcheck/config.toml')
        expected_content = {
          grpc: {
            port: '8001'
          },
          rest: {
            externalPort: ''
          },
          logger: {
            level: 'info',
            format: 'json',
            output: 'stdout'
          },
          monitor: {
            address: ":8003"
          },
          extraAttributes: {
            monitorMode: 'false'
          },
          filter: {
            allowList: {},
            denyList: {}
          },
          preprocessor: {
            socketPath: '/var/opt/gitlab/spamcheck/sockets/preprocessor.sock'
          },
          modelAttributes: {
            modelPath: '/opt/gitlab/embedded/service/spam-classifier/model/issues/tflite/model.tflite'
          }
        }
        expect(actual_content).to eq(expected_content)
      end

      it 'creates env directory with default variables' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/spamcheck/env').with_variables(
          'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
        )
      end

      it_behaves_like "enabled runit service", "spamcheck", "root", "root"
      it_behaves_like "enabled runit service", "spam-classifier", "root", "root"

      it 'creates runit files for spamcheck service' do
        expected_content = <<~EOS
          #!/bin/bash

          # Let runit capture all script error messages
          exec 2>&1

          exec chpst -e /opt/gitlab/etc/spamcheck/env -P \\
            -u git:git \\
            -U git:git \\
            /opt/gitlab/embedded/bin/spamcheck -config /var/opt/gitlab/spamcheck/config.toml
        EOS

        expect(chef_run).to render_file('/opt/gitlab/sv/spamcheck/run').with_content(expected_content)
      end

      it 'creates runit files for spam-classifier service' do
        expected_content = <<~EOS
          #!/bin/bash

          # Let runit capture all script error messages
          exec 2>&1

          exec chpst -e /opt/gitlab/etc/spamcheck/env -P \\
            -u git:git \\
            -U git:git \\
            /opt/gitlab/embedded/bin/python3 /opt/gitlab/embedded/service/spam-classifier/preprocessor/preprocess.py \\
              --tokenizer-pickle-path /opt/gitlab/embedded/service/spam-classifier/preprocessor/tokenizer.pickle \\
              --log-dir /var/log/gitlab/spam-classifier \\
              --socket-dir /var/opt/gitlab/spamcheck/sockets
        EOS

        expect(chef_run).to render_file('/opt/gitlab/sv/spam-classifier/run').with_content(expected_content)
      end
    end

    context 'log directory and runit group' do
      context 'default values' do
        before do
          stub_gitlab_rb(spamcheck: { enable: true })
        end

        it_behaves_like 'enabled logged service', 'spamcheck', true, { log_directory_owner: 'git' }
        it_behaves_like 'enabled logged service', 'spam-classifier', true, { log_directory_owner: 'git' }
      end

      context 'custom values' do
        before do
          stub_gitlab_rb(
            spamcheck: {
              enable: true,
              log_group: 'fugee',
              log_directory: '/log/spamcheck',
              classifier: {
                log_group: 'fugee',
                log_directory: '/log/spam-classifier',
              }
            }
          )
        end
        it_behaves_like 'enabled logged service', 'spamcheck', true, { log_directory_owner: 'git', log_group: 'fugee', log_directory: '/log/spamcheck' }
        it_behaves_like 'enabled logged service', 'spam-classifier', true, { log_directory_owner: 'git', log_group: 'fugee', log_directory: '/log/spam-classifier' }
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          user: {
            username: 'randomuser',
            group: 'randomgroup'
          },
          spamcheck: {
            enable: true,
            dir: '/data/spamcheck',
            port: 5001,
            external_port: 5002,
            monitoring_address: ':5003',
            log_level: 'debug',
            log_format: 'text',
            log_output: 'file',
            monitor_mode: true,
            allowlist: {
              '14' => 'spamtest/hello'
            },
            denylist: {
              '15' => 'foobar/random'
            },
            env_directory: '/env/spamcheck',
            env: {
              'FOO' => 'BAR'
            },
          }
        )
      end

      it 'creates necessary directories at user specified locations' do
        %w[
          /data/spamcheck
          /data/spamcheck/sockets
        ].each do |dir|
          expect(chef_run).to create_directory(dir).with(
            owner: 'randomuser',
            mode: '0700',
            recursive: true
          )
        end
      end

      it 'creates config.toml with user specified values' do
        actual_content = get_rendered_toml(chef_run, '/data/spamcheck/config.toml')
        expected_content = {
          grpc: {
            port: '5001'
          },
          rest: {
            externalPort: '5002'
          },
          logger: {
            level: 'debug',
            format: 'text',
            output: 'file'
          },
          monitor: {
            address: ":5003"
          },
          extraAttributes: {
            monitorMode: 'true'
          },
          filter: {
            allowList: {
              '14': 'spamtest/hello'
            },
            denyList: {
              '15': 'foobar/random'
            }
          },
          preprocessor: {
            socketPath: '/data/spamcheck/sockets/preprocessor.sock'
          },
          modelAttributes: {
            modelPath: '/opt/gitlab/embedded/service/spam-classifier/model/issues/tflite/model.tflite'
          }
        }
        expect(actual_content).to eq(expected_content)
      end

      it 'creates env directory with user specified and default variables' do
        expect(chef_run).to create_env_dir('/env/spamcheck').with_variables(
          'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
          'FOO' => 'BAR'
        )
      end

      it_behaves_like "enabled runit service", "spamcheck", "root", "root"
      it_behaves_like "enabled runit service", "spam-classifier", "root", "root"

      it 'creates runit files for spamcheck service' do
        expected_content = <<~EOS
          #!/bin/bash

          # Let runit capture all script error messages
          exec 2>&1

          exec chpst -e /env/spamcheck -P \\
            -u randomuser:randomgroup \\
            -U randomuser:randomgroup \\
            /opt/gitlab/embedded/bin/spamcheck -config /data/spamcheck/config.toml
        EOS

        expect(chef_run).to render_file('/opt/gitlab/sv/spamcheck/run').with_content(expected_content)
      end

      it 'creates runit files for spam-classifier service' do
        expected_content = <<~EOS
          #!/bin/bash

          # Let runit capture all script error messages
          exec 2>&1

          exec chpst -e /env/spamcheck -P \\
            -u randomuser:randomgroup \\
            -U randomuser:randomgroup \\
            /opt/gitlab/embedded/bin/python3 /opt/gitlab/embedded/service/spam-classifier/preprocessor/preprocess.py \\
              --tokenizer-pickle-path /opt/gitlab/embedded/service/spam-classifier/preprocessor/tokenizer.pickle \\
              --log-dir /var/log/gitlab/spam-classifier \\
              --socket-dir /data/spamcheck/sockets
        EOS

        expect(chef_run).to render_file('/opt/gitlab/sv/spam-classifier/run').with_content(expected_content)
      end
    end
  end

  describe 'spamcheck::disable' do
    it_behaves_like "disabled runit service", "spamcheck", "root", "root"
    it_behaves_like "disabled runit service", "spam-classifier", "root", "root"
  end
end
