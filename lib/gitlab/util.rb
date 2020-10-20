module Gitlab
  class Util
    class << self
      def get_env(key)
        ENV[key]&.strip
      end

      def set_env(key, value)
        ENV[key] = value&.strip
      end

      def set_env_if_missing(key, value)
        ENV[key] ||= value&.strip
      end

      def section(name, description = name, &block)
        section_start(name, description)

        yield

        section_end(name)
      end

      def section_start(name, description = name)
        return unless ENV['CI']

        name.tr!(':', '-')

        @section_name = name
        $stdout.puts "section_start:#{Time.now.to_i}:#{name}\r\e[0K#{description}"
      end

      def section_end(name = @section_name)
        return unless ENV['CI']

        name.tr!(':', '-')

        $stdout.puts "section_end:#{Time.now.to_i}:#{name}\r\e[0K"
      end
    end
  end
end
