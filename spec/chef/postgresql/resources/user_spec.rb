require 'chef_helper'

describe 'postgresql_user' do
  before do
    allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:user_exists?).and_return(false, true)
    allow_any_instance_of(PgHelper).to receive(:user_password_match?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:user_options_set?).and_return(false)
  end

  let(:runner) { ChefSpec::SoloRunner.new(step_into: ['postgresql_user']) }

  context 'create' do
    let(:chef_run) { runner.converge('test_postgresql::postgresql_user_create') }

    it 'creates a user' do
      expect(chef_run).to run_execute('create example postgresql user')
    end
  end

  context 'password' do
    context 'not specified' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_user_password_unspecified') }

      it 'does not set the password of the no_password user' do
        expect(chef_run).not_to run_execute('set password for no_password postgresql user')
      end
    end

    context 'nil' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_user_password_nil') }

      it 'does set the password of the nil_password user' do
        expect(chef_run).to run_execute('set password for nil_password postgresql user')
          .with(command: /PASSWORD NULL/)
      end
    end

    context 'md5' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_user_password_md5') }

      it 'does set the password of the md5_password user' do
        expect(chef_run).to run_execute('set password for md5_password postgresql user')
          .with(command: /PASSWORD 'e99b79fbdf9b997e6918df2385e60f5c'/)
      end
    end

    context 'empty' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_user_password_empty') }

      it 'does set the password of the empty_password user' do
        expect(chef_run).to run_execute('set password for empty_password postgresql user')
          .with(command: /PASSWORD ''/)
      end
    end
  end

  context 'options' do
    context 'unspecified' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_user_options_unspecified') }

      it 'does not set options' do
        expect(chef_run).not_to run_execute('set options for example postgresql user')
      end
    end

    context 'SUPERUSER' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_user_options_superuser') }

      it 'does set SUPERUSER' do
        expect(chef_run).to run_execute('set options for example postgresql user')
          .with(command: /\bSUPERUSER\b/)
      end
    end
  end
end
