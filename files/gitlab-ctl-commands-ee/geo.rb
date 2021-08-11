require 'optparse'

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/geo"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/geo/promote"

add_command_under_category('geo', 'gitlab-geo', 'Interact with Geo', 2) do
  begin
    options = Geo.parse_options(ARGV)
  rescue OptionParser::ParseError => e
    warn "#{e}\n\n#{Geo.usage}"
    exit 128
  end

  case options[:command]
  when 'promote'
    begin
      Geo::Promote.new(self, options).execute
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

    if command.nil? || !Geo.respond_to?(command) || Geo.method(command).arity != 1
      warn "Unknown Geo command: #{options[:command]}"
      exit 128
    end

    begin
      status = Geo.send(command, options)
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
