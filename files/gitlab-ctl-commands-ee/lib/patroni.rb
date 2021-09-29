require 'fileutils'
require 'net/http'
require 'openssl'
require 'optparse'

module Patroni
  USAGE ||= <<~EOS.freeze
    Usage:
      gitlab-ctl patroni [options] command [options]

    GLOBAL OPTIONS:
      -h, --help      Usage help
      -q, --quiet     Silent or quiet mode
      -v, --verbose   Verbose or debug mode

    COMMANDS:
      bootstrap              Bootstraps the node
      check-leader           Check if the current node is the Patroni leader
      check-replica          Check if the current node is a Patroni replica
      check-standby-leader    Check if the current node is the Patroni leader in a standby cluster
      members                List the cluster members
      pause                  Disable auto failover
      resume                 Resume auto failover
      failover               Failover to a replica
      switchover             Switchover to a replica
      reinitialize-replica   Reinitialize replication when in a Patroni replica
      restart                Restart Postgres service without triggering failover
      reload                 Reload Patroni configuration
  EOS

  # rubocop:disable Metrics/AbcSize
  def self.parse_options(args)
    loop do
      break if args.shift == 'patroni'
    end

    options = {}

    global = OptionParser.new do |opts|
      opts.banner = 'patroni [options] command [options]'
      opts.on('-q', '--quiet', 'Silent or quiet mode') do |q|
        options[:quiet] = q
      end
      opts.on('-v', '--verbose', 'Verbose or debug mode') do |v|
        options[:verbose] = v
      end
      opts.on('-h', '--help', 'Usage help') do
        Utils.warn_and_exit usage
      end
    end

    commands = {
      'bootstrap' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
        opts.on('--scope=SCOPE', 'Name of the cluster to be bootstrapped') do |scope|
          options[:scope] = scope
        end
        opts.on('--datadir=DATADIR', 'Path to the data directory of the cluster instance to be bootstrapped') do |datadir|
          options[:datadir] = datadir
        end
        opts.on('--srcdir=SRCDIR', 'Path to the configuration source directory') do |srcdir|
          options[:srcdir] = srcdir
        end
      end,
      'check-leader' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
      end,
      'check-replica' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
      end,
      'check-standby-leader' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
      end,
      'members' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
      end,
      'pause' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
        opts.on('-w', '--wait', 'Wait until pause is applied on all nodes') do |w|
          options[:wait] = w
        end
      end,
      'resume' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
        opts.on('-w', '--wait', 'Wait until pause is cleared on all nodes') do |w|
          options[:wait] = w
        end
      end,
      'failover' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
        opts.on('--master [MASTER]', 'The name of the current master') do |m|
          options[:master] = m
        end
        opts.on('--candidate [CANDIDATE]', 'The name of the candidate') do |c|
          options[:candidate] = c
        end
      end,
      'switchover' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
        opts.on('--master [MASTER]', 'The name of the current master') do |m|
          options[:master] = m
        end
        opts.on('--candidate [CANDIDATE]', 'The name of the candidate') do |c|
          options[:candidate] = c
        end
        opts.on('--scheduled [SCHEDULED]', 'Schedule of switchover') do |t|
          options[:scheduled] = t
        end
      end,
      'restart' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
      end,
      'reload' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
      end,
      'reinitialize-replica' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end
        opts.on('--member [MEMBER]', 'The cluster member name to reinitialize') do |member|
          options[:member] = member
        end
        opts.on('-w', '--wait', 'Wait until reinitialization completes') do |wait|
          options[:wait] = wait
        end
      end
    }

    global.order! args
    command = args.shift

    raise OptionParser::ParseError, "Patroni command is not specified." \
      if command.nil? || command.empty?

    raise OptionParser::ParseError, "Unknown Patroni command: #{command}" \
      unless commands.key? command

    options[:command] = command
    commands[command].order! args
    options
  end
  # rubocop:enable Metrics/AbcSize

  def self.usage
    USAGE
  end

  def self.init_db(options)
    GitlabCtl::Util.run_command("/opt/gitlab/embedded/bin/initdb -D #{options[:datadir]} -E UTF8")
  end

  def self.copy_config(options)
    FileUtils.cp_r "#{options[:srcdir]}/.", options[:datadir]
  end

  def self.leader?(options)
    Client.new.leader?
  end

  def self.replica?(options)
    Client.new.replica?
  end

  def self.standby_leader?(options)
    Client.new.standby_leader?
  end

  def self.members(options)
    Utils.patronictl('list')
  end

  def self.pause(options)
    command = %w(pause)
    command << '-w' if options[:wait]
    Utils.patronictl(command)
  end

  def self.resume(options)
    command = %w(resume)
    command << '-w' if options[:wait]
    Utils.patronictl(command)
  end

  def self.failover(options)
    command = %w(failover)
    command << "--force"
    command << "--master #{options[:master]}" if options[:master]
    command << "--candidate #{options[:candidate]}" if options[:candidate]
    Utils.patronictl(command)
  end

  def self.switchover(options)
    command = %w(switchover)
    command << "--force"
    command << "--master #{options[:master]}" if options[:master]
    command << "--candidate #{options[:candidate]}" if options[:candidate]
    command << "--scheduled #{options[:scheduled]}" if options[:scheduled]
    Utils.patronictl(command)
  end

  def self.restart(options)
    patroni = patroni_attributes
    Utils.patronictl("restart --force #{patroni['scope']} #{patroni['name']}")
  end

  def self.reload(options)
    patroni = patroni_attributes
    Utils.patronictl("reload --force #{patroni['scope']} #{patroni['name']}")
  end

  def self.reinitialize_replica(options)
    patroni = patroni_attributes
    command = %w(reinit)
    command << '--force'
    command << '--wait' if options[:wait]
    command << patroni['scope']
    command << (options[:member].nil? ? patroni['name'] : options[:member])
    Utils.patronictl(command, live: true)
  end

  def self.patroni_attributes
    patroni = GitlabCtl::Util.get_node_attributes['patroni']
    Utils.no_config_error! if patroni.nil?

    patroni
  end

  class Utils
    def self.patronictl(cmd, user = 'root', live: false)
      patroni = GitlabCtl::Util.get_public_node_attributes['patroni']
      no_config_error! if patroni.nil?

      GitlabCtl::Util.run_command(
        "/opt/gitlab/embedded/bin/patronictl -c #{patroni['config_dir']}/patroni.yaml #{cmd.respond_to?(:join) ? cmd.join(' ') : cmd.to_s}",
        user: user, live: live)
    end

    def self.no_config_error!
      raise <<~EOS.freeze
        This node has no Patroni configuration! This could mean:
          - either your Omnibus is misconfigured,
          - or you need to run this command on a database node.
      EOS
    end

    def self.warn_and_exit(msg, code = 0)
      Kernel.warn msg
      Kernel.exit(code)
    end
  end

  ClientError = Class.new(StandardError)

  class Client
    attr_accessor :uri

    def initialize
      @attributes = GitlabCtl::Util.get_public_node_attributes
      @uri = URI(attribute('api_address'))
    end

    def up?
      get('/') do
        return true
      end
    rescue StandardError
      false
    end

    def leader?
      get('/leader') do |response|
        response.code == '200'
      end
    end

    def replica?
      get('/replica') do |response|
        response.code == '200'
      end
    end

    def standby_leader?
      get('/standby-leader') do |response|
        response.code == '200'
      end
    end

    def cluster_status
      get('/cluster') do |response|
        response.code == '200' ? JSON.parse(response.body, symbolize_names: true) : {}
      end
    end

    private

    def attribute(name)
      @attributes['patroni'][name]
    end

    def http_options
      opts = {}

      return opts unless @uri.scheme == 'https'

      opts[:use_ssl] = true
      if attribute('tls_verify')
        opts[:ca_file] = attribute('ca_file')
      else
        opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
      end

      opts.merge!(
        verify_mode: OpenSSL::SSL::VERIFY_PEER,
        cert: OpenSSL::X509::Certificate.new(File.read(attribute('client_cert'))),
        key: OpenSSL::PKey.read(File.read(attribute('client_key')))
      ) if attribute('verify_client')

      opts.compact
    end

    def get(endpoint, header = nil)
      Net::HTTP.start(@uri.host, @uri.port, http_options) do |http|
        http.request_get(endpoint, header) do |response|
          return yield response
        end
      end
    end
  end
end
