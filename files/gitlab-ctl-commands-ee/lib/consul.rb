require 'mixlib/shellout'

require_relative 'repmgr'

class Consul
  class WatcherError < StandardError; end

  attr_accessor :command, :subcommand, :input

  def initialize(argv, input = nil)
    @command = Kernel.const_get("#{self.class}::#{argv[3].capitalize}")
    @subcommand = argv[4].tr('-', '_')
    @input = input
  end

  def execute
    command.send(subcommand, input)
  end

  class Kv
    class << self
      def put(key, value = nil)
        run_consul("kv put #{key} #{value}")
      end

      def delete(key)
        run_consul("kv delete #{key}")
      end

      protected

      def run_consul(cmd)
        command = Mixlib::ShellOut.new("/opt/gitlab/embedded/bin/consul #{cmd}")
        command.run_command
        begin
          command.error!
        rescue StandardError => e
          puts e
          puts command.stderr
        end
      end
    end
  end

  class Watchers
    class << self
      def handle_failed_master(input)
        return if input.chomp.eql?('null')

        node = Repmgr::Node.new
        unless node.is_master?
          # wait 5 seconds for the actual master node to handle the removal
          sleep 5
          return
        end

        begin
          data = JSON.parse(input)
        rescue JSON::ParserError
          raise Consul::WatcherError, "Invalid input detected: '#{input}'"
        end

        data.each do |fm|
          node_id = fm['Key'].split('/').last
          begin
            Repmgr::Master.remove(node_id: node_id, user: 'gitlab-consul')
          rescue StandardError
            Consul::Kv.put(fm['Key'])
          else
            Consul::Kv.delete(fm['Key'])
          end
        end
      end
    end
  end
end
