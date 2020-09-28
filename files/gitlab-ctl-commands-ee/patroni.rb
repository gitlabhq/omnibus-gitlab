require 'optparse'

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/patroni"

add_command_under_category('patroni', 'database', 'Interact with Patroni', 2) do
  begin
    options = Patroni.parse_options(ARGV)
  rescue OptionParser::ParseError => e
    warn "#{e}\n\n#{Patroni.usage}"
    exit 128
  end

  case options[:command]
  when 'bootstrap'
    log 'Bootstrapping the current node'
    begin
      status = Patroni.init_db options
      log status.stdout
      if status.error?
        warn '===STDERR==='
        warn status.stderr
        warn '======'
        warn 'Error bootstrapping Patroni node. Please check the error output'
        exit status.exitstatus
      end

      log 'Copying PostgreSQL configuration'
      Patroni.copy_config options

      log 'Current node is bootstrapped'
      exit 0
    rescue StandardError => e
      warn "Error while bootsrapping the current node: #{e}" unless options[:quiet]
      exit 3
    end

  when 'check-leader'
    begin
      if Patroni.leader? options
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
      if Patroni.replica? options
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

  else
    # Try to handle the command with fallback procedure. The command:
    #   . Must not include `_` or `?`
    #   . Must be a method of Patroni module
    #   . Must accept one argument

    command = options[:command].match?(/[_?]/) ? nil : options[:command].to_sym

    if command.nil? || !Patroni.respond_to?(command) || Patroni.method(command).arity != 1
      warn "Unknown Patroni command: #{options[:command]}"
      exit 128
    end

    begin
      status = Patroni.send(command, options)
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
