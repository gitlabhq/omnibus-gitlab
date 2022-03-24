# frozen_string_literal: true

require 'chef_helper'
require 'time'

RSpec.describe OmnibusHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  let(:file) { double(:file, write: true) }

  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with('/etc/gitlab/initial_root_password', 'w', 0600).and_yield(file).once
  end

  describe '#user_exists?' do
    it 'returns true when user exists' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("id -u root").and_return(true)
      expect(subject.user_exists?('root')).to be_truthy
    end

    it 'returns false when user does not exist' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("id -u nonexistentuser").and_return(false)
      expect(subject.user_exists?('nonexistentuser')).to be_falsey
    end
  end

  describe '#group_exists?' do
    it 'returns true when group exists' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("getent group root").and_return(true)
      expect(subject.group_exists?('root')).to be_truthy
    end

    it 'returns false when group does not exist' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("getent group nonexistentgroup").and_return(false)
      expect(subject.group_exists?('nonexistentgroup')).to be_falsey
    end
  end

  describe '#not_listening?' do
    let(:chef_run) { converge_config }
    context 'when Redis is disabled' do
      before do
        stub_gitlab_rb(
          redis: { enable: false }
        )
      end

      it 'returns true when service is disabled' do
        expect(subject.not_listening?('redis')).to be_truthy
      end
    end

    context 'when Redis is enabled' do
      before do
        stub_gitlab_rb(
          redis: { enable: true }
        )
      end

      it 'returns true when service is down' do
        stub_service_failure_status('redis', true)

        expect(subject.not_listening?('redis')).to be_truthy
      end

      it 'returns false when service is up' do
        stub_service_failure_status('redis', false)

        expect(subject.not_listening?('redis')).to be_falsey
      end
    end
  end

  describe '#service_enabled?' do
    context 'services are enabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = true
        chef_run.node.normal['new_service']['enable'] = true
        chef_run.node.normal['monitoring']['another_service']['enable'] = true
      end

      it 'should return true' do
        expect(subject.service_enabled?('old_service')).to be_truthy
        expect(subject.service_enabled?('new_service')).to be_truthy
        expect(subject.service_enabled?('another_service')).to be_truthy
      end
    end

    context 'services are disabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = false
        chef_run.node.normal['new_service']['enable'] = false
        chef_run.node.normal['monitoring']['another_service']['enable'] = false
      end

      it 'should return false' do
        expect(subject.service_enabled?('old_service')).to be_falsey
        expect(subject.service_enabled?('new_service')).to be_falsey
        expect(subject.service_enabled?('another_service')).to be_falsey
      end
    end
  end

  describe '#is_managed_and_offline?' do
    context 'services are disabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = false
        chef_run.node.normal['new_service']['enable'] = false
      end

      it 'returns false' do
        expect(subject.is_managed_and_offline?('old_service')).to be_falsey
        expect(subject.is_managed_and_offline?('new_service')).to be_falsey
      end
    end

    context 'services are enabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = true
        chef_run.node.normal['new_service']['enable'] = true
      end

      it 'returns true when services are offline' do
        stub_service_failure_status('old_service', true)
        stub_service_failure_status('new_service', true)

        expect(subject.is_managed_and_offline?('old_service')).to be_truthy
        expect(subject.is_managed_and_offline?('new_service')).to be_truthy
      end

      it 'returns false when services are online ' do
        stub_service_failure_status('old_service', false)
        stub_service_failure_status('new_service', false)

        expect(subject.is_managed_and_offline?('old_service')).to be_falsey
        expect(subject.is_managed_and_offline?('new_service')).to be_falsey
      end
    end
  end

  describe '#is_deprecated_os?' do
    before do
      allow(OmnibusHelper).to receive(:deprecated_os_list).and_return({ "raspbian-8.0" => "GitLab 11.8" })
    end

    it 'detects deprecated OS correctly' do
      allow_any_instance_of(Ohai::System).to receive(:data).and_return({ "platform" => "raspbian", "platform_version" => "8.0" })

      OmnibusHelper.is_deprecated_os?

      expect_logged_deprecation(/Your OS, raspbian-8.0, will be deprecated soon/)
    end

    it 'does not detects valid OS as deprecated' do
      allow_any_instance_of(Ohai::System).to receive(:data).and_return({ "platform" => "ubuntu", "platform_version" => "16.04.3" })
      expect(LoggingHelper).not_to receive(:deprecation)
      OmnibusHelper.is_deprecated_os?
    end
  end

  describe '#is_deprecated_praefect_config?' do
    before do
      chef_run.node.normal['praefect'] = config
    end

    context 'deprecated config' do
      let(:config) do
        {
          storage_nodes: [
            { storage: 'praefect1', address: 'tcp://node1.internal' },
            { storage: 'praefect2', address: 'tcp://node2.internal' }
          ]
        }
      end

      it 'detects deprecated config correctly' do
        subject.is_deprecated_praefect_config?

        expect_logged_deprecation(/Specifying Praefect storage nodes as an array is deprecated/)
      end
    end

    context 'valid config' do
      let(:config) do
        {
          storage_nodes: {
            'praefect1' => { address: 'tcp://node1.internal' },
            'praefect2' => { address: 'tcp://node2.internal' }
          }
        }
      end

      it 'does not detect a valid config as deprecated' do
        expect(LoggingHelper).not_to receive(:deprecation)

        subject.is_deprecated_praefect_config?
      end
    end
  end

  describe '#write_root_password' do
    before do
      stub_gitlab_rb(
        gitlab_rails: {
          initial_root_password: 'foobar',
          store_initial_root_password: true
        }
      )
    end

    it 'stores root password to /etc/gitlab/initial_root_password' do
      content = <<~EOS
        # WARNING: This value is valid only in the following conditions
        #          1. If provided manually (either via `GITLAB_ROOT_PASSWORD` environment variable or via `gitlab_rails['initial_root_password']` setting in `gitlab.rb`, it was provided before database was seeded for the first time (usually, the first reconfigure run).
        #          2. Password hasn't been changed manually, either via UI or via command line.
        #
        #          If the password shown here doesn't work, you must reset the admin password following https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password.

        Password: foobar

        # NOTE: This file will be automatically deleted in the first reconfigure run after 24 hours.
      EOS

      expect(file).to receive(:write).with(content)

      described_class.new(converge_config.node).write_root_password
    end
  end

  describe '.cleanup_root_password_file' do
    context 'when /etc/gitlab/initial_root_password does not exist' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('/etc/gitlab/initial_root_password').and_return(false)
      end

      it 'does not attempt to remove the file' do
        expect(FileUtils).not_to receive(:rm_f).with('/etc/gitlab/initial_root_password')

        described_class.cleanup_root_password_file
      end
    end

    context 'when /etc/gitlab/initial_root_password exists' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('/etc/gitlab/initial_root_password').and_return(true)
        allow(Time).to receive(:now).and_return(Time.parse('2021-06-07 08:45:51.377926667 +0530'))
      end

      context 'when file is older than 24 hours' do
        before do
          allow(File).to receive(:mtime).with('/etc/gitlab/initial_root_password').and_return(Time.parse('2021-06-03 06:45:51.377926667 +0530'))
        end

        it 'attempts to remove the file' do
          expect(FileUtils).to receive(:rm_f).with('/etc/gitlab/initial_root_password')

          described_class.cleanup_root_password_file

          expect_logged_note('Found old initial root password file at /etc/gitlab/initial_root_password and deleted it.')
        end
      end

      context 'when file is younger than 24 hours' do
        before do
          allow(File).to receive(:mtime).with('/etc/gitlab/initial_root_password').and_return(Time.parse('2021-06-08 06:45:51.377926667 +0530'))
        end

        it 'does not attempt to remove the file' do
          expect(FileUtils).not_to receive(:rm_f).with('/etc/gitlab/initial_root_password')

          described_class.cleanup_root_password_file

          expect_logged_note('Found old initial root password file at /etc/gitlab/initial_root_password and deleted it.')
        end
      end
    end
  end

  describe '#print_root_account_details' do
    context 'when not on first reconfigure after installation' do
      before do
        chef_run.node.normal['gitlab']['bootstrap']['enable'] = false
      end

      it 'does not add a note or write password to file' do
        expect(LoggingHelper).not_to receive(:note)
        expect(subject).not_to receive(:write_root_password)

        subject.print_root_account_details
      end
    end

    context 'when on first reconfigure after installation' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:writ_root_password).and_return(true)
      end

      context 'when display_initial_root_password is true' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              initial_root_password: 'foobar',
              display_initial_root_password: true,
              store_initial_root_password: false
            }
          )
        end

        it 'displays root password at the end of reconfigure' do
          msg = <<~EOS
            Default admin account has been configured with following details:
            Username: root
            Password: foobar

            NOTE: Because these credentials might be present in your log files in plain text, it is highly recommended to reset the password following https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password.
          EOS

          described_class.new(converge_config.node).print_root_account_details

          expect_logged_note(msg)
        end
      end

      context 'when display_initial_root_password is false' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              initial_root_password: 'foobar',
              display_initial_root_password: false,
              store_initial_root_password: false
            }
          )
        end

        it 'does not display root credentials at the end of reconfigure' do
          msg = <<~EOS
            Default admin account has been configured with following details:
            Username: root
            Password: You didn't opt-in to print initial root password to STDOUT.

            NOTE: Because these credentials might be present in your log files in plain text, it is highly recommended to reset the password following https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password.
          EOS

          described_class.new(converge_config.node).print_root_account_details

          expect_logged_note(msg)
        end
      end

      describe '#write_root_password' do
        context 'when store_initial_root_password is true' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                initial_root_password: 'foobar',
                display_initial_root_password: false,
                store_initial_root_password: true
              }
            )
          end

          it 'writes initial root password to /etc/gitlab/initial_root_password' do
            subject = described_class.new(converge_config.node)
            expect(subject).to receive(:write_root_password)

            subject.print_root_account_details

            expect_logged_note(%r{Password stored to /etc/gitlab/initial_root_password})
          end
        end

        context 'with default value for store_initial_root_password' do
          context 'when password is auto-generated' do
            before do
              allow(ENV).to receive(:[]).and_call_original
              allow(ENV).to receive(:[]).with('GITLAB_ROOT_PASSWORD').and_return(nil)
            end

            it 'writes initial root password to /etc/gitlab/initial_root_password' do
              chef_run = ChefSpec::SoloRunner.converge('gitlab::default')
              subject = described_class.new(chef_run.node)

              expect(subject).to receive(:write_root_password)

              subject.print_root_account_details

              expect_logged_note(%r{Password stored to /etc/gitlab/initial_root_password})
            end
          end

          context 'when password is specified by user' do
            context 'via gitlab.rb' do
              before do
                stub_gitlab_rb(
                  gitlab_rails: {
                    initial_root_password: 'foobar',
                  }
                )
              end

              it 'does not write initial root password to /etc/gitlab/initial_root_password' do
                subject = described_class.new(converge_config.node)

                expect(subject).not_to receive(:write_root_password)

                subject.print_root_account_details
              end
            end

            context 'via env variable' do
              before do
                allow(ENV).to receive(:[]).and_call_original
                allow(ENV).to receive(:[]).with('GITLAB_ROOT_PASSWORD').and_return('foobar')
              end

              it 'does not write initial root password to /etc/gitlab/initial_root_password' do
                subject = described_class.new(converge_config.node)

                expect(subject).not_to receive(:write_root_password)

                subject.print_root_account_details
              end
            end
          end
        end
      end
    end
  end

  describe '#check_locale' do
    let(:error_message) { "Identified encoding is not UTF-8. GitLab requires UTF-8 encoding to function properly. Please check your locale settings." }

    describe 'using LC_ALL variable' do
      it 'does not raise a warning when set to a UTF-8 locale even if others are not' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return('en_US.UTF-8')
        allow(ENV).to receive(:[]).with('LC_COLLATE').and_return('en_SG ISO-8859-1')
        allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_SG ISO-8859-1')
        allow(ENV).to receive(:[]).with('LANG').and_return('en_SG ISO-8859-1')

        expect(LoggingHelper).not_to receive(:warning).with("Environment variable .* specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

        described_class.check_locale
      end

      it 'raises warning when LC_ALL is non-UTF-8' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return('en_SG ISO-8859-1')

        described_class.check_locale

        expect_logged_warning("Environment variable LC_ALL specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")
      end
    end

    describe 'using LC_CTYPE variable' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return(nil)
      end

      it 'raises warning when LC_CTYPE is non-UTF-8' do
        allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_SG ISO-8859-1')

        described_class.check_locale

        expect_logged_warning("Environment variable LC_CTYPE specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")
      end
    end

    describe 'using LC_COLLATE variable' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return(nil)
        allow(ENV).to receive(:[]).with('LC_CTYPE').and_return(nil)
      end

      it 'raises warning when LC_COLLATE is non-UTF-8' do
        allow(ENV).to receive(:[]).with('LC_COLLATE').and_return('en_SG ISO-8859-1')

        described_class.check_locale

        expect_logged_warning("Environment variable LC_COLLATE specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")
      end
    end

    describe 'using LANG variable' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return(nil)
      end

      context 'without LC_CTYPE and LC_COLLATE' do
        before do
          allow(ENV).to receive(:[]).with('LC_CTYPE').and_return(nil)
          allow(ENV).to receive(:[]).with('LC_COLLATE').and_return(nil)
        end

        it 'raises warning when LANG is non-UTF-8' do
          allow(ENV).to receive(:[]).with('LANG').and_return('en_SG ISO-8859-1')

          described_class.check_locale

          expect_logged_warning("Environment variable LANG specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")
        end
      end

      context 'with only LC_CTYPE set to UTF-8' do
        before do
          allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_US.UTF-8')
          allow(ENV).to receive(:[]).with('LC_COLLATE').and_return(nil)
        end

        it 'raises warning when LANG is non-UTF-8' do
          allow(ENV).to receive(:[]).with('LANG').and_return('en_SG ISO-8859-1')

          described_class.check_locale

          expect_logged_warning("Environment variable LANG specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")
        end
      end

      context 'with both LC_CTYPE and LC_COLLATE set to UTF-8' do
        before do
          allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_US.UTF-8')
          allow(ENV).to receive(:[]).with('LC_COLLATE').and_return('en_US.UTF-8')
        end

        it 'does not raise a warning even if LANG is not UTF-8' do
          described_class.check_locale

          expect_logged_warning("Environment variable LANG specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")
        end
      end
    end
  end

  describe '.resource_available?' do
    cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
    subject(:omnibus_helper) { described_class.new(chef_run.node) }

    it 'returns false for a resource that exists but has not been loaded in runtime' do
      expect(omnibus_helper.resource_available?('runit_service[geo-logcursor]')).to be_falsey
    end

    it 'returns true for a resource that exists and is loaded in runtime' do
      expect(omnibus_helper.resource_available?('runit_service[logrotated]'))
    end
  end
end
