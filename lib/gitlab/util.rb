module Gitlab
  class Util
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
    end
  end
end
