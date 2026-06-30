require 'optparse'

require "#{base_path}/embedded/cookbooks/package/libraries/gitlab_cluster"
require "gitlab_ctl"
require "gitlab_ctl/geo"
require "gitlab_ctl/geo/promote"

add_command_under_category('geo', 'gitlab-geo', 'Interact with Geo', 2) do
  begin
    options = GitlabCtl::Geo.parse_options(ARGV)
  rescue OptionParser::ParseError => e
    warn "#{e}\n\n#{GitlabCtl::Geo.usage}"
    exit 128
  end

  case options[:command]
  when 'promote'
    begin
      GitlabCtl::Geo::Promote.new(self, options).execute
      exit 0
    rescue StandardError => e
      warn "Error while promoting the current node: #{e}" unless options[:quiet]
      exit 3
    end

  else
    # Try to handle the command with fallback procedure. The command:
    #   . Must not include `_` or `?`
    #   . Must be a method of Geo module
    #   . Must accept one argument

    command = options[:command].match?(/[_?]/) ? nil : options[:command].to_sym

    if command.nil? || !GitlabCtl::Geo.respond_to?(command) || GitlabCtl::Geo.method(command).arity != 1
      warn "Unknown Geo command: #{options[:command]}"
      exit 128
    end

    begin
      status = GitlabCtl::Geo.send(command, options)
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
