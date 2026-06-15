# Copyright:: Copyright (c) 2026 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'digest'
require 'mixlib/shellout'
require 'shellwords'
require 'yaml'

# Identity-only registry for non-Rails component PostgreSQL databases
# that live on the same physical cluster as the Rails database.
#
# Operator schema (in /etc/gitlab/gitlab.rb):
#
#   postgresql['component_databases'] = {
#     'gate' => {
#       'enable'      => true,
#       'database'    => 'gate_production', # PG db name; defaults to key
#       'user'        => 'gate',            # role owning the DB
#       'password'    => '...',             # auto-MD5 if not already hashed
#       'extensions'  => ['pg_trgm'],       # optional list
#       'system_user' => 'gate',            # OS username for UNIX-socket peer
#                                           # auth; defaults to `user`
#       'extra_config_command' => '/path/to/secret-fetcher', # optional
#     }
#   }
#
# `system_user` is rendered into pg_ident.conf as
#   gitlab  <system_user>  <user>
# so a component process running as that OS user can connect over the
# UNIX socket without a password. Defaulting to `user` keeps the
# common case (same OS and PG name) explicit -- the catch-all
# `gitlab /^(.*)$ \1` mapping already covers it, but emitting a real
# line gives operators and test suites something concrete to assert on.
#
# `extra_config_command` is executed at parse-time. Its stdout is parsed
# as YAML (JSON is a valid subset) and merged into the entry, with
# command-provided values overriding any static declaration for the same
# field. See apply_extra_config_command! below.
#
# This library does NOT decide pooling, replication, backup, monitoring,
# or Geo participation. Each consumer (pgbouncer, pgb-notify, backup,
# monitoring) reads the registry and applies its own policy via its own
# attributes.
module ComponentDatabaseRegistry
  REQUIRED_FIELDS = %w[user].freeze

  CommandExecutionError = Class.new(StandardError)

  class << self
    # Parse-time entry point invoked from Postgresql.parse_variables.
    # Validates and normalizes Gitlab['postgresql']['component_databases']
    # in place.
    def parse_variables
      Gitlab['postgresql']['component_databases'] ||= {}

      Gitlab['postgresql']['component_databases'].each do |key, config|
        next unless config.is_a?(Hash) && config['enable'] == true

        apply_extra_config_command!(key, config)
        validate!(key, config)
        normalize!(key, config)
      end
    end

    # Returns the enabled entries in a source hash (defaults to the
    # parsed SettingsDSL view). Callers may pass a node attribute mash:
    #
    #   ComponentDatabaseRegistry.enabled_entries(node['postgresql']['component_databases'])
    def enabled_entries(source = nil)
      source ||= Gitlab['postgresql']['component_databases'] || {}

      source.each_with_object({}) do |(key, config), acc|
        next unless config.is_a?(Hash) && config['enable'] == true

        acc[key] = config
      end
    end

    # Component database names (the PG `database` field, falling back to
    # the registry key).
    def names(source = nil)
      enabled_entries(source).map { |key, config| config['database'] || key }
    end

    # Unique set of PG roles that applications use to connect to the
    # registered databases. Used by pgbouncer's pg_auth wiring.
    def users(source = nil)
      enabled_entries(source).map { |_, config| config['user'] }.compact.uniq
    end

    # Unique set of PG roles that own the registered databases. Falls
    # back to `user` when `owner` is unset (matches the normalize-time
    # default).
    def owners(source = nil)
      enabled_entries(source).map { |_, config| config['owner'] || config['user'] }.compact.uniq
    end

    # `[system_user, pg_user]` pairs for every registered entry, in
    # registration order. Consumed by the pg_ident.conf template to
    # emit `gitlab <system_user> <pg_user>` map lines so UNIX-socket
    # peer auth works without a per-component cookbook patch.
    def system_user_mappings(source = nil)
      enabled_entries(source).map do |_, config|
        [config['system_user'] || config['user'], config['user']]
      end
    end

    private

    # Run the operator-supplied `extra_config_command` (when set) and merge
    # its YAML/JSON output into the entry. Mirrors the same pattern Rails
    # uses via `gitlab_rails['db_extra_config_command']`, but executed
    # parse-time so the fetched values participate in validation and
    # password normalization, and so consumers (postgresql_user resource,
    # pgbouncer pg_auth template) see the materialized fields.
    #
    # Output contract: a YAML document whose top-level node is a mapping
    # of registry-entry fields. JSON is a valid subset and accepted as-is.
    # Command-provided values override statically declared values for the
    # same key; the typical use is a static skeleton in /etc/gitlab/gitlab.rb
    # with secret fields supplied by the fetcher.
    #
    # Failure modes deliberately do NOT echo command stdout or stderr,
    # since the payload is a secret. Errors reference the entry key and
    # the command path only.
    def apply_extra_config_command!(key, config)
      command = config['extra_config_command']
      return if command.nil? || command.to_s.empty?

      output = run_extra_config_command(key, command)
      merged = parse_extra_config_output(key, command, output)

      # String-key normalization so symbol-key YAML (`password: foo`)
      # round-trips into the string-keyed config hash the rest of the
      # registry uses.
      merged.transform_keys!(&:to_s)

      config.merge!(merged)
    end

    # Hard cap on how long a single extra_config_command may take.
    # Long enough for a vault/secrets-manager round trip; short enough
    # that a hung fetcher fails reconfigure loudly rather than silently
    # blocking it for hours.
    EXTRA_CONFIG_COMMAND_TIMEOUT_SECONDS = 30

    def run_extra_config_command(key, command)
      # Shellwords.split honours POSIX shell quoting, so an operator
      # can supply paths with spaces (`/opt/my scripts/fetcher`) or
      # quoted arguments (`fetcher --env "prod env"`) and have them
      # tokenised the same way the shell would.
      shellout = Mixlib::ShellOut.new(
        *Shellwords.split(command),
        timeout: EXTRA_CONFIG_COMMAND_TIMEOUT_SECONDS
      )

      begin
        shellout.run_command
      rescue Errno::ENOENT
        raise CommandExecutionError,
              "Component database '#{key}' extra_config_command failed: " \
              "`#{command}` does not exist or is not executable"
      rescue Mixlib::ShellOut::CommandTimeout
        raise CommandExecutionError,
              "Component database '#{key}' extra_config_command `#{command}` " \
              "timed out after #{EXTRA_CONFIG_COMMAND_TIMEOUT_SECONDS}s"
      end

      return shellout.stdout if shellout.status.success?

      # Surface enough to debug (stderr is operator-authored script output,
      # not the secret payload that goes to stdout) without leaking the
      # YAML/JSON that would have been merged into the entry.
      raise CommandExecutionError,
            "Component database '#{key}' extra_config_command `#{command}` " \
            "exited with status #{shellout.exitstatus}: #{shellout.stderr.strip}"
    end

    def parse_extra_config_output(key, command, output)
      parsed = begin
        # Symbol is permitted so a YAML mapping with `:password:` (symbol
        # key) round-trips; we transform_keys to_s in the caller. Every
        # other Ruby-tagged class (`!ruby/object:...`) is rejected --
        # that's what the safe_load posture buys us.
        YAML.safe_load(output, permitted_classes: [Symbol], aliases: false) || {}
      rescue Psych::Exception => e
        raise CommandExecutionError,
              "Component database '#{key}' extra_config_command `#{command}` " \
              "did not return valid YAML/JSON: #{e.message}"
      end

      return parsed if parsed.is_a?(Hash)

      raise CommandExecutionError,
            "Component database '#{key}' extra_config_command `#{command}` " \
            "must return a top-level mapping (got #{parsed.class})"
    end

    def validate!(key, config)
      REQUIRED_FIELDS.each do |field|
        next unless config[field].nil? || config[field].to_s.empty?

        raise "Component database '#{key}' is missing required field '#{field}'"
      end
    end

    # An md5-prefixed PostgreSQL password literal: the token `md5`
    # followed by exactly 32 lowercase hex characters (the output of
    # Digest::MD5.hexdigest). Anything else is treated as plaintext.
    MD5_PREHASHED_RE = /\Amd5[0-9a-f]{32}\z/.freeze

    def normalize!(key, config)
      config['database'] ||= key
      config['extensions'] ||= []

      # `owner` lets operators separate database ownership from the
      # application connect-user. It defaults to `user` when unset, and
      # empty-string is treated the same way -- downstream consumers
      # use the `||` predicate, which keeps an empty string and would
      # then issue `CREATE DATABASE ... OWNER ""`.
      config['owner'] = config['user'] if config['owner'].nil? || config['owner'].to_s.empty?

      # `system_user` is the OS username the component process runs as,
      # mapped to `user` in pg_ident.conf for UNIX-socket peer auth. We
      # always materialise an explicit value (defaulting to `user`) so
      # downstream consumers and test expectations have a concrete
      # field to read.
      config['system_user'] = config['user'] if config['system_user'].nil? || config['system_user'].to_s.empty?

      pw = config['password']
      return if pw.nil?

      # Always store the password as raw md5 hex. Downstream consumers
      # -- the postgresql_user resource creating the role and the
      # pgbouncer pg_auth template -- add the `md5` prefix themselves
      # before passing the value to PostgreSQL / pgbouncer. If we kept a
      # `md5<hex>` operator input verbatim here, the resource would emit
      # `md5md5<hex>`, PG would treat it as an invalid hash and re-encode
      # it under the default password_encryption (SCRAM-SHA-256).
      #
      # The strict regex prevents misidentifying a plaintext password
      # that simply begins with "md5" (e.g. "md5secret") as pre-hashed.
      normalized = pw.match?(MD5_PREHASHED_RE) ? pw.delete_prefix('md5') : md5_password(pw, config['user'])
      config['password'] = normalized
    end

    def md5_password(password, username)
      return nil if password.nil?

      Digest::MD5.hexdigest(password + username.to_s)
    end
  end
end
