require 'optparse'

require "gitlab_ctl"
require "gitlab_ctl/praefect"

add_command_under_category('praefect', 'gitaly', 'Interact with Gitaly cluster', 2) do
  begin
    options = GitlabCtl::Praefect.parse_options!(ARGV)
  rescue OptionParser::ParseError => e
    warn "#{e}\n\n#{GitlabCtl::Praefect::USAGE}"
    exit 128
  end

  puts "Running #{options[:command]}"
  GitlabCtl::Praefect.execute(options)
  exit 0
end
