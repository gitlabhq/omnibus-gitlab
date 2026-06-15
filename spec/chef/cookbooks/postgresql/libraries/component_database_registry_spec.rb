require 'chef_helper'

RSpec.describe ComponentDatabaseRegistry do
  before do
    Gitlab['postgresql']['component_databases'] = nil
  end

  describe '.parse_variables' do
    it 'initializes component_databases to {} when unset' do
      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']).to eq({})
    end

    it 'rejects non-strict enable values (regression: 1, "true", etc.)' do
      # Consumers use strict `config['enable'] == true`. parse_variables
      # must apply the same predicate so truthy-but-not-true values
      # don't pass validation here and silently disappear downstream.
      Gitlab['postgresql']['component_databases'] = {
        'one' => { 'enable' => 1,      'user' => 'one' },
        'two' => { 'enable' => 'true', 'user' => 'two' }
      }

      # Neither entry is `== true`, so neither is normalized.
      described_class.parse_variables
      expect(described_class.enabled_entries.keys).to be_empty
    end

    it 'raises when an enabled entry is missing required user field' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'password' => 'secret' }
      }

      expect { described_class.parse_variables }
        .to raise_error(/missing required field 'user'/)
    end

    it 'raises when user is set to an empty string' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => '', 'password' => 'x' }
      }

      expect { described_class.parse_variables }
        .to raise_error(/missing required field 'user'/)
    end

    it 'leaves password as nil when none is supplied' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate' }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['password']).to be_nil
    end

    it 'skips disabled entries' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => false, 'password' => 'plain' }
      }

      expect { described_class.parse_variables }.not_to raise_error
      expect(Gitlab['postgresql']['component_databases']['gate']['password']).to eq('plain')
    end

    it 'normalizes plain passwords to md5<user+pw> format' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'password' => 'secret' }
      }

      described_class.parse_variables

      expected = Digest::MD5.hexdigest('secretgate')
      expect(Gitlab['postgresql']['component_databases']['gate']['password']).to eq(expected)
    end

    it 'treats a plaintext password that starts with "md5" as plaintext (regression)' do
      # Regression: a previous version stripped any string starting with
      # 'md5'. A plaintext password like "md5secret" would lose its
      # leading three chars; downstream would prepend `md5` again, PG
      # would reject the bogus hash and re-encode as SCRAM. The strict
      # md5+32hex regex prevents this.
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'password' => 'md5secret' }
      }

      described_class.parse_variables

      expected = Digest::MD5.hexdigest('md5secretgate')
      expect(Gitlab['postgresql']['component_databases']['gate']['password']).to eq(expected)
    end

    it 'strips the md5 prefix from a pre-hashed password (no double-hash)' do
      # Operators supplying `md5<32-char hex>` are giving us a
      # pre-computed md5(password + username) hash. Downstream consumers
      # prepend `md5` themselves, so we store only the raw hex; otherwise
      # PG would see `md5md5<hex>` and reject it as an invalid hash.
      hex = 'deadbeefdeadbeefdeadbeefdeadbeef'
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'password' => "md5#{hex}" }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['password']).to eq(hex)
    end

    it 'defaults database to the registry key and extensions to []' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate' }
      }

      described_class.parse_variables

      entry = Gitlab['postgresql']['component_databases']['gate']
      expect(entry['database']).to eq('gate')
      expect(entry['extensions']).to eq([])
    end

    it 'defaults owner to the user when owner is unset' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate' }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['owner']).to eq('gate')
    end

    it 'treats empty-string owner as unset and falls back to user' do
      # Downstream consumers use `config["owner"] || username`; an empty
      # string is truthy so it would slip through and issue
      # `CREATE DATABASE ... OWNER ""`. Normalize that case here.
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'owner' => '' }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['owner']).to eq('gate')
    end

    it 'preserves an explicit owner distinct from user' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'owner' => 'gate_admin' }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['owner']).to eq('gate_admin')
    end

    it 'defaults system_user to the user when system_user is unset' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate' }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['system_user']).to eq('gate')
    end

    it 'treats empty-string system_user as unset and falls back to user' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'system_user' => '' }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['system_user']).to eq('gate')
    end

    it 'preserves an explicit system_user distinct from user' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate_admin', 'system_user' => 'git' }
      }

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['system_user']).to eq('git')
    end

    it 'preserves an explicit database and extensions' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => {
          'enable' => true, 'user' => 'gate',
          'database' => 'gate_production', 'extensions' => %w[pg_trgm]
        }
      }

      described_class.parse_variables

      entry = Gitlab['postgresql']['component_databases']['gate']
      expect(entry['database']).to eq('gate_production')
      expect(entry['extensions']).to eq(%w[pg_trgm])
    end
  end

  describe '.parse_variables with extra_config_command' do
    let(:cmd) { '/etc/gitlab/fetch-gate' }
    let(:ok_status) { instance_double(Process::Status, success?: true) }
    let(:bad_status) { instance_double(Process::Status, success?: false) }

    def shellout_double(stdout: '', stderr: '', success: true)
      instance_double(
        Mixlib::ShellOut,
        run_command: nil,
        stdout: stdout,
        stderr: stderr,
        status: success ? ok_status : bad_status,
        exitstatus: success ? 0 : 2
      )
    end

    def stub_extra_command(stdout: '', stderr: '', success: true)
      allow(Mixlib::ShellOut).to receive(:new)
        .with(cmd, timeout: 30)
        .and_return(shellout_double(stdout: stdout, stderr: stderr, success: success))
    end

    it 'merges YAML output into the entry' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      stub_extra_command(stdout: "password: gatesekrit\n")

      described_class.parse_variables

      entry = Gitlab['postgresql']['component_databases']['gate']
      # password gets MD5-normalized by normalize! after the merge
      expect(entry['password']).to eq(Digest::MD5.hexdigest('gatesekritgate'))
    end

    it 'accepts JSON output (YAML superset)' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      stub_extra_command(stdout: '{"password": "gatesekrit"}')

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['password'])
        .to eq(Digest::MD5.hexdigest('gatesekritgate'))
    end

    it 'tokenises the command with Shellwords so a quoted path with spaces stays one argv element' do
      quoted = '"/opt/my scripts/fetcher"'
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => quoted }
      }
      expect(Mixlib::ShellOut).to receive(:new)
        .with('/opt/my scripts/fetcher', timeout: 30)
        .and_return(shellout_double(stdout: "password: gatesekrit\n"))

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['password'])
        .to eq(Digest::MD5.hexdigest('gatesekritgate'))
    end

    it 'tokenises quoted arguments as a single argv element (regression: naive split would break this)' do
      quoted_args = '/etc/gitlab/fetch --env "prod env"'
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => quoted_args }
      }
      expect(Mixlib::ShellOut).to receive(:new)
        .with('/etc/gitlab/fetch', '--env', 'prod env', timeout: 30)
        .and_return(shellout_double(stdout: "password: gatesekrit\n"))

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['password'])
        .to eq(Digest::MD5.hexdigest('gatesekritgate'))
    end

    it 'overrides statically declared values for any key the command supplies' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => {
          'enable' => true, 'user' => 'gate', 'password' => 'static',
          'extra_config_command' => cmd
        }
      }
      stub_extra_command(stdout: "password: fromcommand\n")

      described_class.parse_variables

      expect(Gitlab['postgresql']['component_databases']['gate']['password'])
        .to eq(Digest::MD5.hexdigest('fromcommandgate'))
    end

    it 'preserves statically declared keys the command does not supply' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => {
          'enable' => true, 'user' => 'gate', 'database' => 'gate_production',
          'extensions' => %w[pg_trgm], 'extra_config_command' => cmd
        }
      }
      stub_extra_command(stdout: "password: gatesekrit\n")

      described_class.parse_variables

      entry = Gitlab['postgresql']['component_databases']['gate']
      expect(entry['database']).to eq('gate_production')
      expect(entry['extensions']).to eq(%w[pg_trgm])
    end

    it 'is a no-op when the command field is empty string' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => '' }
      }
      expect(Mixlib::ShellOut).not_to receive(:new)

      described_class.parse_variables
    end

    it 'skips disabled entries even when extra_config_command is set' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => false, 'extra_config_command' => cmd }
      }
      expect(Mixlib::ShellOut).not_to receive(:new)

      described_class.parse_variables
    end

    it 'raises a CommandExecutionError when the command is missing on disk' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      shellout = instance_double(Mixlib::ShellOut)
      allow(shellout).to receive(:run_command).and_raise(Errno::ENOENT)
      allow(Mixlib::ShellOut).to receive(:new).with(cmd, timeout: 30).and_return(shellout)

      expect { described_class.parse_variables }.to raise_error(
        ComponentDatabaseRegistry::CommandExecutionError,
        /Component database 'gate'.*does not exist or is not executable/
      )
    end

    it 'raises a CommandExecutionError when the command exceeds the timeout' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      shellout = instance_double(Mixlib::ShellOut)
      allow(shellout).to receive(:run_command).and_raise(Mixlib::ShellOut::CommandTimeout)
      allow(Mixlib::ShellOut).to receive(:new).with(cmd, timeout: 30).and_return(shellout)

      expect { described_class.parse_variables }.to raise_error(
        ComponentDatabaseRegistry::CommandExecutionError,
        /timed out after 30s/
      )
    end

    it 'raises with stderr when the command exits non-zero' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      stub_extra_command(stderr: 'vault timed out', success: false)

      expect { described_class.parse_variables }.to raise_error(
        ComponentDatabaseRegistry::CommandExecutionError,
        /exited with status 2: vault timed out/
      )
    end

    it 'does not echo command stdout on non-zero exit (secret-leak guard)' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      stub_extra_command(stdout: 'password: leakedsecret', stderr: 'oops', success: false)

      expect { described_class.parse_variables }.to raise_error(
        ComponentDatabaseRegistry::CommandExecutionError
      ) { |e| expect(e.message).not_to include('leakedsecret') }
    end

    it 'raises on invalid YAML' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      stub_extra_command(stdout: "password: [unterminated")

      expect { described_class.parse_variables }.to raise_error(
        ComponentDatabaseRegistry::CommandExecutionError,
        /did not return valid YAML\/JSON/
      )
    end

    it 'raises when the top-level output is not a mapping' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      stub_extra_command(stdout: "- one\n- two\n")

      expect { described_class.parse_variables }.to raise_error(
        ComponentDatabaseRegistry::CommandExecutionError,
        /must return a top-level mapping/
      )
    end

    it 'rejects unsafe YAML tags (safe_load posture)' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      # `--- !ruby/object:...` would deserialize an arbitrary class under
      # YAML.unsafe_load; safe_load with permitted_classes: [] must reject.
      stub_extra_command(stdout: "--- !ruby/object:Gem::Installer {}\n")

      expect { described_class.parse_variables }.to raise_error(
        ComponentDatabaseRegistry::CommandExecutionError
      )
    end

    it 'normalizes symbol keys from YAML to string keys' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      # `:password:` in YAML deserializes the key as a Symbol; without
      # the transform_keys, the merged entry would carry the symbol key
      # alongside (or shadowing) the string key, and downstream consumers
      # iterating .each would see two entries -- a string key check on
      # the underlying Hash confirms the symbol form was rewritten.
      stub_extra_command(stdout: ":password: gatesekrit\n")

      described_class.parse_variables

      entry = Gitlab['postgresql']['component_databases']['gate']
      expect(entry.keys).to include('password')
      expect(entry.keys).not_to include(:password)
      expect(entry['password']).to eq(Digest::MD5.hexdigest('gatesekritgate'))
    end

    it 'tolerates an empty stdout (parses to {})' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'extra_config_command' => cmd }
      }
      stub_extra_command(stdout: '')

      expect { described_class.parse_variables }.not_to raise_error
    end
  end

  describe '.enabled_entries' do
    it 'returns only enabled entries' do
      source = {
        'one' => { 'enable' => true, 'user' => 'one' },
        'two' => { 'enable' => false, 'user' => 'two' },
        'three' => { 'user' => 'three' }
      }

      expect(described_class.enabled_entries(source).keys).to eq(['one'])
    end

    it 'ignores non-Hash values defensively' do
      source = { 'one' => nil, 'two' => 'bogus', 'three' => { 'enable' => true, 'user' => 'u' } }

      expect(described_class.enabled_entries(source).keys).to eq(['three'])
    end

    it 'falls back to Gitlab["postgresql"]["component_databases"] when source is nil' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate' }
      }

      expect(described_class.enabled_entries.keys).to eq(['gate'])
    end

    it 'returns {} when neither source nor Gitlab fallback has entries' do
      Gitlab['postgresql']['component_databases'] = nil

      expect(described_class.enabled_entries).to eq({})
    end
  end

  describe '.names' do
    it 'uses the database field, falling back to the registry key' do
      source = {
        'a' => { 'enable' => true, 'user' => 'a', 'database' => 'a_prod' },
        'b' => { 'enable' => true, 'user' => 'b' }
      }

      expect(described_class.names(source)).to contain_exactly('a_prod', 'b')
    end

    it 'falls back to the Gitlab source when none is passed' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'database' => 'gate_production' }
      }

      expect(described_class.names).to eq(['gate_production'])
    end
  end

  describe '.users' do
    it 'returns the unique set of PG roles' do
      source = {
        'a' => { 'enable' => true, 'user' => 'shared' },
        'b' => { 'enable' => true, 'user' => 'shared' },
        'c' => { 'enable' => true, 'user' => 'distinct' }
      }

      expect(described_class.users(source)).to contain_exactly('shared', 'distinct')
    end

    it 'falls back to the Gitlab source when none is passed' do
      Gitlab['postgresql']['component_databases'] = {
        'gate' => { 'enable' => true, 'user' => 'gate' }
      }

      expect(described_class.users).to eq(['gate'])
    end
  end

  describe '.owners' do
    it 'returns the explicit owner when set' do
      source = {
        'a' => { 'enable' => true, 'user' => 'a', 'owner' => 'a_admin' },
        'b' => { 'enable' => true, 'user' => 'b', 'owner' => 'shared_admin' },
        'c' => { 'enable' => true, 'user' => 'c', 'owner' => 'shared_admin' }
      }

      expect(described_class.owners(source)).to contain_exactly('a_admin', 'shared_admin')
    end

    it 'falls back to user when owner is unset on a particular entry' do
      source = {
        'a' => { 'enable' => true, 'user' => 'a' },
        'b' => { 'enable' => true, 'user' => 'b', 'owner' => 'b_admin' }
      }

      expect(described_class.owners(source)).to contain_exactly('a', 'b_admin')
    end
  end

  describe '.system_user_mappings' do
    it 'returns [system_user, user] pairs in registration order' do
      source = {
        'gate' => { 'enable' => true, 'user' => 'gate', 'system_user' => 'gate' },
        'openbao' => { 'enable' => true, 'user' => 'openbao', 'system_user' => 'openbao' }
      }

      expect(described_class.system_user_mappings(source)).to eq(
        [%w[gate gate], %w[openbao openbao]]
      )
    end

    it 'falls back to user when system_user is unset on a particular entry' do
      source = {
        'a' => { 'enable' => true, 'user' => 'a' },
        'b' => { 'enable' => true, 'user' => 'b_role', 'system_user' => 'b_proc' }
      }

      expect(described_class.system_user_mappings(source)).to eq(
        [%w[a a], %w[b_proc b_role]]
      )
    end

    it 'omits disabled entries' do
      source = {
        'on' => { 'enable' => true, 'user' => 'on' },
        'off' => { 'enable' => false, 'user' => 'off' }
      }

      expect(described_class.system_user_mappings(source)).to eq([%w[on on]])
    end
  end
end
