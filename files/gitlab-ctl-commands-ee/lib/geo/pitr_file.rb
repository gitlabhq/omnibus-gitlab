# frozen_string_literal: true

require_relative 'promote_db'
require_relative '../consul'

module Geo
  class PitrFile
    attr_accessor :filepath, :consul_key, :fallback_filepath

    NAMESPACE = 'geo/pitr'
    PITR_FILE_NAME = 'geo-pitr-file'
    CONSUL_PITR_KEY = 'promote-db'

    # @param [Object] ctl the omnibus-ctl object associated with the command
    def initialize(ctl)
      @filepath = "#{GitlabCtl::Util.get_public_node_attributes.dig('postgresql', 'dir')}/data/#{PITR_FILE_NAME}"
      @consul_key = "#{NAMESPACE}/#{CONSUL_PITR_KEY}".downcase

      # TODO: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8970
      # Remove the line below after required stop, to ensure that nobody will be using the fallback path anymore
      @fallback_filepath = "#{ctl.data_path}/postgresql/data/#{PITR_FILE_NAME}"
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
    rescue Errno::ENOENT, ConsulHandler::ConsulError
      raise PitrFileError, "Unable to create PITR"
    end

    def delete
      if use_consul?
        ConsulHandler::Kv.delete(consul_key)
      else
        File.delete(filepath) if File.exist?(filepath)
        # TODO: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8970
        # Remove the line below after required stop, to ensure that nobody will be using the fallback path anymore
        File.delete(fallback_filepath) if File.exist?(fallback_filepath)
      end
    rescue Errno::ENOENT, ConsulHandler::ConsulError
      raise PitrFileError, "Unable to delete PITR"
    end

    def get
      if use_consul?
        ConsulHandler::Kv.get(consul_key)
      elsif File.exist?(filepath)
        File.read(filepath)
      else
        # TODO: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8970
        # Remove the line below as well as the check for file existence above after required stop,
        # to ensure that nobody will be using the fallback path anymore
        File.read(fallback_filepath)
      end
    rescue Errno::ENOENT, ConsulHandler::ConsulError
      raise PitrFileError, "Unable to fetch PITR"
    end
  end

  PitrFileError = Class.new(StandardError)
end
