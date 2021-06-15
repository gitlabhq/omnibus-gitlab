# frozen_string_literal: true

require_relative 'promote_db'
require_relative '../consul'

module Geo
  class PitrFile
    attr_accessor :filepath, :consul_key

    NAMESPACE = 'geo/pitr'

    # @param [String] filepath a full path for a on disk PITR file
    # @param [String] consul_key a consul key to be instead used when consul is available
    def initialize(filepath, consul_key:)
      @filepath = filepath
      @consul_key = "#{NAMESPACE}/#{consul_key}".downcase
    end

    def use_consul?
      Dir.exist?('/opt/gitlab/service/consul')
    end

    # Create a PITR file storing a point-in-time LSN reference
    #
    # @param [String] lsn point-in-time LSN reference
    def create(lsn)
      if use_consul?
        ConsulHandler::Kv.put(consul_key, lsn)
      else
        File.write(filepath, lsn)
      end
    end

    def delete
      if use_consul?
        ConsulHandler::Kv.delete(consul_key)
      elsif File.exist?(filepath)
        File.delete(filepath)
      end
    rescue Errno::ENOENT, ConsulHandler::ConsulError
      raise PitrFileError, "Unable to delete PITR"
    end

    def get
      if use_consul?
        ConsulHandler::Kv.get(consul_key)
      else
        File.read(filepath)
      end
    rescue Errno::ENOENT, ConsulHandler::ConsulError
      raise PitrFileError, "Unable to fetch PITR"
    end
  end

  PitrFileError = Class.new(StandardError)
end
