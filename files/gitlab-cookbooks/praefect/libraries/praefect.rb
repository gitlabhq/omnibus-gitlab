module Praefect
  class << self
    def parse_variables
      parse_virtual_storages
    end

    def parse_virtual_storages
      return if Gitlab['praefect']['virtual_storages'].nil?

      raise "Praefect virtual_storages must be a hash" unless Gitlab['praefect']['virtual_storages'].is_a?(Hash)

      Gitlab['praefect']['virtual_storages'].each do |virtual_storage, config_keys|
        next unless config_keys.key?('nodes')

        raise "Nodes of Praefect virtual storage `#{virtual_storage}` must be a hash" unless config_keys['nodes'].is_a?(Hash)
      end
    end
  end
end
