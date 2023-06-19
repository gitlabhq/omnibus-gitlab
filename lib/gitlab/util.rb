module Gitlab
  class Util
    class ShellOutExecutionError < StandardError
      attr_accessor :stdout, :stderr

      def initialize(command, exitcode, stdout, stderr)
        @stdout = stdout
        @stderr = stderr
        msg = "Execution of command `#{command}` failed with exit code #{exitcode}."

        super(msg)
      end
    end

    class << self
      def get_env(key)
        value = ENV[key]&.strip

        value unless value&.empty?
      end

      def set_env(key, value)
        ENV[key] = value&.strip
      end

      def set_env_if_missing(key, value)
        ENV[key] ||= value&.strip
      end

      def section(name, collapsed: true)
        return yield unless ENV['CI']

        name.tr!(':', '-')

        collapsed_mark = collapsed ? '[collapsed=true]' : ''
        $stdout.puts "section_start:#{Time.now.to_i}:#{name}#{collapsed_mark}\r\e[0K#{name}"

        yield

        $stdout.puts "section_end:#{Time.now.to_i}:#{name}\r\e[0K"
      end

      def fetch_fact_from_file(fact)
        return unless File.exist?("build_facts/#{fact}")

        content = File.read("build_facts/#{fact}").strip
        return content unless content.empty?
      end
    end
  end
end
