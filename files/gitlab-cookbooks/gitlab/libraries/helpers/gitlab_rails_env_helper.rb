class GitlabRailsEnvHelper
  class << self
    # Get the db version from the rails environment
    def db_version
      PGVersion.parse(execute_rails_ruby(db_version_command).lines.last.chomp)
    end

    def db_version_command
      %w(
        require "yaml";
        require "active_record";

        ActiveRecord::Base.establish_connection(YAML.load_file("config/database.yml")["production"]["main"]);
        version_row = ActiveRecord::Base.connection.execute("SELECT VERSION()").first;
        puts version_row["version"].match(Regexp.new("\\\A(?:PostgreSQL |)([^\\\s]+).*\\\z"))[1];
      ).join(' ')
    end

    # Get the path to Gemfile from bundle config file which is generated at build time
    def bundle_gemfile(source_dir)
      gemfile = "#{source_dir}/Gemfile"
      pattern = /BUNDLE_GEMFILE: "(.*)"/
      begin
        File.open("#{source_dir}/.bundle/config") do |config_file|
          config_file.each do |line|
            if line.match(pattern)
              gemfile = "#{source_dir}/#{line[pattern, 1]}"
              break
            end
          end
        end
      rescue Errno::ENOENT
        gemfile
      end
      gemfile
    end

    def execute_rails_ruby(cmd)
      run_shell = Mixlib::ShellOut.new(%W(
        /opt/gitlab/bin/gitlab-ruby
        -e '#{cmd}'
      ).join(" "))
      run_shell.run_command
      run_shell.error!
      run_shell.stdout
    end
  end
end
