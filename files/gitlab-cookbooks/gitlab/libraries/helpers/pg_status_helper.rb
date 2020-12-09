# This is a helper to establish the listening status of PostgreSQL
require_relative 'base_helper'
require_relative '../../../package/libraries/helpers/shell_out_helper'

class PgStatusHelper
  include ShellOutHelper

  attr_reader :maximum_service_checks
  attr_reader :total_service_checks
  attr_reader :service_check_interval
  attr_reader :service_checks

  def initialize(connection_info, node)
    @conn = connection_info
    @total_service_checks = 0
    @maximum_service_checks = node['postgresql']['max_service_checks']
    @service_check_interval = node['postgresql']['service_check_interval']
    @service_checks = {}
    @status_executable = "#{node['package']['install-dir']}/embedded/bin/pg_isready"
  end

  # Mutator Methods
  def remaining_service_checks
    @maximum_service_checks - @total_service_checks
  end

  def service_checks_exhausted?
    remaining_service_checks < 1
  end

  # Check Methods
  [
    'accepting_connections?',
    'rejecting_connections?',
    'not_responding?',
    'invalid_connection_parameters?'
  ].each.with_index do |method, index|
    define_method method do
      service_state == index
    end
  end

  def ready?
    @total_service_checks = 1

    until accepting_connections?
      warning = if invalid_connection_parameters?
                  "PostgreSQL is not receiving the correct connection parameters"
                elsif service_checks_exhausted?
                  if not_responding?
                    "PostgreSQL did not respond before service checks were exhausted"
                  else
                    "Exhausted service checks and database is still not available"
                  end
                end
      raise warning unless warning.nil?

      sleep(service_check_interval)
      @total_service_checks += 1
    end

    true
  end

  def service_state
    return @service_checks[@total_service_checks] if @service_checks.include?(@total_service_checks)

    cmd = %W(#{@status_executable} -d #{@conn.dbname} -h #{@conn.dbhost} -p #{@conn.port} -U #{@conn.pguser})

    @service_checks[@total_service_checks] = do_shell_out(cmd).exitstatus
  end
end
