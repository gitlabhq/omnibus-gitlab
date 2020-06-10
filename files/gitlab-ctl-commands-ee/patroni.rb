require 'optparse'

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/patroni"
require "#{base_path}/embedded/service/omnibus-ctl/lib/postgresql"

add_command_under_category('patroni', 'database', 'Interact with Patroni', 2) do
  begin
    options = Patroni.parse_options(ARGV)
  rescue OptionParser::ParseError => e
    warn e
    Kernel.exit 128
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
        Kernel.exit status.exitstatus
      end

      log 'Copying PostgreSQL configuration'
      Patroni.copy_config options

      log 'Current node is bootstrapped'
      Kernel.exit 0
    rescue StandardError => e
      warn "Error while bootsrapping the current node: #{e}" unless options[:quiet]
      Kernel.exit 3
    end

  when 'check-leader'
    begin
      if Patroni.leader? options
        warn 'I am the leader.' unless options[:quiet]
        Kernel.exit 0
      else
        warn 'I am not the leader.' unless options[:quiet]
        Kernel.exit 1
      end
    rescue StandardError => e
      warn "Error while checking the role of the current node: #{e}" unless options[:quiet]
      Kernel.exit 3
    end

  when 'check-replica'
    begin
      if Patroni.replica? options
        warn 'I am a replica.' unless options[:quiet]
        Kernel.exit 0
      else
        warn 'I am not a replica.' unless options[:quiet]
        Kernel.exit 1
      end
    rescue StandardError => e
      warn "Error while checking the role of the current node: #{e}" unless options[:quiet]
      Kernel.exit 3
    end

  end
end
