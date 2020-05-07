require "http"

module Gitlab
  class DockerImageMemoryMeasurer
    attr_accessor :image_reference, :debug_output_dir, :container_log_file, :pid_command_map_file, :smem_result_file

    def initialize(image_reference, debug_output_dir = nil)
      @image_reference = image_reference
      @debug_output_dir = debug_output_dir

      set_debug_output_file_names
    end

    def set_debug_output_file_names
      if debug_output_dir.nil?
        @container_log_file = nil
        @pid_command_map_file = nil
        @smem_result_file = nil
      else
        @container_log_file = File.join(debug_output_dir, 'container_setup.log')
        @pid_command_map_file = File.join(debug_output_dir, 'pid_command_map.txt')
        @smem_result_file = File.join(debug_output_dir, 'smem_result.txt')
      end
    end

    def authenticate
      Docker.authenticate!(username: 'gitlab-ci-token', password: Gitlab::Util.get_env('CI_JOB_TOKEN'), serveraddress: Gitlab::Util.get_env('CI_REGISTRY'))
    end

    def measure
      authenticate
      container = start_docker_container
      pid_command_hash_array, smem_result_hash_array = container_memory_usage_raw_data(container)

      smem_result_hash_array = add_full_command_and_component_to_smem_result_hash(pid_command_hash_array, smem_result_hash_array)
      sum_by_component_hash_array = sum_memory_by_component(smem_result_hash_array)

      smem_sum_hash_as_metrics(sum_by_component_hash_array)
    end

    def start_docker_container
      image = Docker::Image.create('fromImage' => image_reference)
      abort "pull image failed: #{image_reference}" unless image

      container = Docker::Container.create(
        'Image' => image_reference,
        'detach' => true,
        # update monitoring_whitelist to allow 'http://docker/-/readiness' access
        'Env' => ["GITLAB_OMNIBUS_CONFIG=gitlab_rails['monitoring_whitelist'] = ['0.0.0.0/0'];"],
        'HostConfig' => {
          'PortBindings' => {
            '80/tcp' => [{ 'HostPort' => '80' }],
            '443/tcp' => [{ 'HostPort' => '443' }],
            '22/tcp' => [{ 'HostPort' => '22' }]
          }
        }
      )
      abort "container create failed: #{image_reference}" unless container

      container.start

      # wait until Gitlab started
      gitlab_started = false
      gitlab_ready = false
      wait_gitlab_start_seconds = ENV.fetch('WAIT_GITLAB_START_SECONDS', 360).to_i
      wait_gitlab_start_seconds.times do
        gitlab_started ||= check_url_alive("http://docker/api/v4/groups")
        gitlab_ready ||= check_gitlab_ready("http://docker/-/readiness")

        break if gitlab_started && gitlab_ready

        sleep 1
      end

      abort "Gitlab services failed to start within #{wait_gitlab_start_seconds} seconds" unless gitlab_started && gitlab_ready

      # wait until Gitlab is hot. Gitlab services take a while to be `hot` after started.
      sleep(120)

      container
    end

    def check_url
      yield
    rescue StandardError
      false
    end

    def check_url_alive(url)
      check_url do
        ret_code = HTTP.get(url).code
        ret_code == 200
      end
    end

    def legacy_readiness_format_status_ok?(hash)
      return false unless hash.is_a?(Hash) && !hash.empty?

      status_ok = true
      hash.each do |key, value|
        status_ok = false unless value.is_a?(Hash) && value['status'] == 'ok'
      end

      status_ok
    end

    def new_readiness_format_status_ok?(hash)
      hash['status'] == 'ok' && hash['master_check'].include?({ 'status' => 'ok' })
    rescue StandardError
      false
    end

    def status_ok?(hash)
      new_readiness_format_status_ok?(hash) || legacy_readiness_format_status_ok?(hash)
    end

    def check_gitlab_ready(url)
      check_url do
        response = JSON.parse(HTTP.get(url))
        status_ok?(response)
      end
    end

    # Why we need the USERS_MEASURE_OMNIBUS_MEMORY?
    # Because `smem` only give processes under current user.
    # To get all interested processes information under user `git`, we do `su -c "smem" git`
    # We do `su -c "smem" <user>` for all <user> listed in USERS_MEASURE_OMNIBUS_MEMORY
    USERS_MEASURE_OMNIBUS_MEMORY = ['git', 'gitlab-prometheus', 'gitlab-psql', 'gitlab-redis', 'gitlab-www', 'root'].freeze
    def container_memory_usage_raw_data(container)
      # install smem
      command = ["bash", "-c", "apt-get update"]
      container_exec_command(container, command, container_log_file)

      command = ["bash", "-c", "apt-get install smem -y"]
      container_exec_command(container, command, container_log_file)

      # get uss/pss/rss
      smem_result_hash_array = []
      USERS_MEASURE_OMNIBUS_MEMORY.each do |user|
        smem_command = ["bash", "-c", "su -s /bin/bash -c \"smem -c 'pid user uss pss rss vss command'\" #{user}"]
        smem_command_return = container_exec_command(container, smem_command, smem_result_file)

        smem_result_hash_array_single_user = stdout_to_hash_array(smem_command_return, /\s+/)

        smem_result_hash_array.concat(smem_result_hash_array_single_user)
      end

      # get <pid, command> map
      # `smem` truncate the `command`, this make it hard to map the process memory usage to the component(like `Unicorn`, `Sidekiq`, etc)
      # Example of `smem` output:
      #     PID User     Command                         Swap      USS      PSS      RSS
      #     316 git      /opt/gitlab/embedded/bin/gi     3504      432      443     1452
      #     312 git      /bin/bash /opt/gitlab/embed      148      240      523     2476
      #
      # We use `ps -ax -o pid -o command` to get processes full command line.
      # Example of `ps -ax -o pid -o command` output
      #     PID COMMAND
      #     312 /bin/bash /opt/gitlab/embedded/bin/gitlab-unicorn-wrapper
      #     316 /opt/gitlab/embedded/bin/gitaly-wrapper /opt/gitlab/embedded/bin/gitaly /var/opt/gitlab/gitaly/config.toml
      #
      # Both results have `pid`, which allow to get `full command` for processes in `smem` result.
      ps_command = ["bash", "-c", "ps -ax -o \"%p<Pid_Command_Separator>\" -o command"]
      ps_command_return = container_exec_command(container, ps_command, pid_command_map_file)

      pid_command_hash_array = stdout_to_hash_array(ps_command_return, /<Pid_Command_Separator>/)

      [pid_command_hash_array, smem_result_hash_array]
    end

    def container_exec_command(container, command, log_file, timeout = 120)
      # make sure the folder exists
      FileUtils.mkdir_p debug_output_dir unless debug_output_dir.nil?

      stdout, stderr, code = container.exec(command, wait: timeout)
      stdout = stdout.join('')
      stderr = stderr.join('')

      File.write(log_file, stdout, mode: 'a') unless debug_output_dir.nil?
      File.write(log_file, stderr, mode: 'a') unless debug_output_dir.nil?

      abort stderr unless code.zero?

      stdout
    end

    # convert stdout to hash array
    def stdout_to_hash_array(stdout, separator)
      processes = stdout.split(/\n+/).map { |l| l.strip.split(separator) }
      headers = processes.shift
      processes.map! { |p| Hash[headers.zip(p)] }
    end

    def component_command_patterns
      {
        'unicorn' => /(^unicorn master)|(^unicorn worker)/,
        'sidekiq' => /^sidekiq /,
        'gitaly' => /(^\/opt\/gitlab\/embedded\/bin\/gitaly)|(^ruby \/opt\/gitlab\/embedded\/service\/gitaly-ruby\/bin\/gitaly-ruby)/,
        'prometheus' => /^\/opt\/gitlab\/embedded\/bin\/prometheus/,
        'postgres' => /(^\/opt\/gitlab\/embedded\/bin\/postgres)|(^postgres:)/,
        'gitlab-exporter' => /^\[gitlab-exporter\]/,
        'workhorse' => /^\/opt\/gitlab\/embedded\/bin\/gitlab-workhorse/,
        'redis' => /^\/opt\/gitlab\/embedded\/bin\/redis_exporter/
      }
    end

    def find_component(command)
      result = []
      component_command_patterns.each do |component, pattern|
        result << component if command&.match(pattern)
      end

      abort "Command(#{command}) matches more than one components: #{result}. Check component_command_patterns: #{component_command_patterns}." if result.size > 1

      result[0]
    end

    def add_full_command_and_component_to_smem_result_hash(pid_command_hash_array, smem_result_hash_array)
      pid_command_map = {}
      pid_command_hash_array.each do |p|
        pid_command_map[p['PID']] = p['COMMAND']
      end

      smem_result_hash_array.each do |p|
        p['COMMAND'] = pid_command_map[p['PID']]
        p['COMPONENT'] = find_component(p['COMMAND'])
      end

      smem_result_hash_array
    end

    def sum_memory_by_component(smem_result_hash_array)
      results = Hash.new { |h, k| h[k] = { 'USS' => 0, 'PSS' => 0, 'RSS' => 0 } }
      smem_result_hash_array.each do |h|
        cummulative_hash = results[h['COMPONENT']]
        cummulative_hash['USS'] += h['USS'].to_f
        cummulative_hash['PSS'] += h['PSS'].to_f
        cummulative_hash['RSS'] += h['RSS'].to_f
      end

      results
    end

    def smem_sum_hash_as_metrics(smem_sum_hash)
      result = []

      smem_sum_hash.each do |key, value|
        component = key
        next if component.nil?

        uss = value['USS'].to_f.round(1)
        pss = value['PSS'].to_f.round(1)
        rss = value['RSS'].to_f.round(1)

        result << "uss_size_kb{component=\"#{component}\"} #{uss}"
        result << "pss_size_kb{component=\"#{component}\"} #{pss}"
        result << "rss_size_kb{component=\"#{component}\"} #{rss}"
      end

      result
    end
  end
end
