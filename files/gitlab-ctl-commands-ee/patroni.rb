require 'optparse'

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/gitlab_ctl/patroni"

add_command_under_category('patroni', 'database', 'Interact with Patroni', 2) do
  begin
    options = GitlabCtl::Patroni.parse_options(ARGV)
  rescue OptionParser::ParseError => e
    warn "#{e}\n\n#{GitlabCtl::Patroni.usage}"
    exit 128
  end

  case options[:command]
  when 'bootstrap'
    log 'Bootstrapping the current node'
    begin
      status = GitlabCtl::Patroni.init_db options
      log status.stdout
      if status.error?
        warn '===STDERR==='
        warn status.stderr
        warn '======'
        warn 'Error bootstrapping Patroni node. Please check the error output'
        exit status.exitstatus
      end

      log 'Copying PostgreSQL configuration'
      GitlabCtl::Patroni.copy_config options

      log 'Current node is bootstrapped'
      exit 0
    rescue StandardError => e
      warn "Error while bootsrapping the current node: #{e}" unless options[:quiet]
      exit 3
    end

  when 'check-leader'
    begin
      if GitlabCtl::Patroni.leader? options
        warn 'I am the leader.' unless options[:quiet]
        exit 0
      else
        warn 'I am not the leader.' unless options[:quiet]
        exit 1
      end
    rescue StandardError => e
      warn "Error while checking the role of the current node: #{e}" unless options[:quiet]
      exit 3
    end

  when 'check-replica'
    begin
      if GitlabCtl::Patroni.replica? options
        warn 'I am a replica.' unless options[:quiet]
        exit 0
      else
        warn 'I am not a replica.' unless options[:quiet]
        exit 1
      end
    rescue StandardError => e
      warn "Error while checking the role of the current node: #{e}" unless options[:quiet]
      exit 3
    end

  when 'check-standby-leader'
    begin
      if GitlabCtl::Patroni.standby_leader? options
        warn 'I am the leader.' unless options[:quiet]
        exit 0
      else
        warn 'I am not the leader.' unless options[:quiet]
        exit 1
      end
    rescue StandardError => e
      warn "Error while checking the role of the current node: #{e}" unless options[:quiet]
      exit 3
    end

  when 'reinitialize-replica'
    begin
      GitlabCtl::Patroni.reinitialize_replica options
      exit 0
    rescue StandardError => e
      warn "Error while reinitializing replica on the current node: #{e}" unless options[:quiet]
      exit 3
    end

  else
    # Try to handle the command with fallback procedure. The command:
    #   . Must not include `_` or `?`
    #   . Must be a method of Patroni module
    #   . Must accept one argument

    command = options[:command].match?(/[_?]/) ? nil : options[:command].to_sym

    if command.nil? || !GitlabCtl::Patroni.respond_to?(command) || GitlabCtl::Patroni.method(command).arity != 1
      warn "Unknown Patroni command: #{options[:command]}"
      exit 128
    end

    begin
      status = GitlabCtl::Patroni.send(command, options)
      log status.stdout
      if status.error?
        warn status.stderr
        exit status.exitstatus
      end
    rescue StandardError => e
      warn "Error while running #{options[:command]}: #{e}" unless options[:quiet]
      exit 3
    end
  end
end
