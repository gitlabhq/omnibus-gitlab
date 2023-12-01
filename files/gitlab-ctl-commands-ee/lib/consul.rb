require 'mixlib/shellout'

class ConsulHandler
  WatcherError = Class.new(StandardError)

  attr_accessor :command, :subcommand, :input

  def initialize(argv, input = nil)
    @command = Kernel.const_get("#{self.class}::#{argv[3].capitalize}")
    @subcommand = argv[4].tr('-', '_')
    @input = input
  end

  def execute
    command.send(subcommand, input)
  end

  class << self
    def run_consul(cmd)
      command = Mixlib::ShellOut.new("/opt/gitlab/embedded/bin/consul #{cmd}")
      command.run_command
      begin
        command.error!
      rescue StandardError => e
        puts e
        puts command.stderr
        raise ConsulError, "#{e}: #{command.stderr}"
      end
      command.stdout
    end
  end

  class Kv
    class << self
      def put(key, value = nil)
        ConsulHandler.run_consul("kv put #{key} #{value}")
      end

      def delete(key)
        ConsulHandler.run_consul("kv delete #{key}")
      end

      def get(key)
        ConsulHandler.run_consul("kv get #{key}")
      end
    end
  end

  class Encrypt
    class << self
      def keygen
        ConsulHandler.run_consul("keygen")
      end
    end
  end

  ConsulError = Class.new(StandardError)
end
