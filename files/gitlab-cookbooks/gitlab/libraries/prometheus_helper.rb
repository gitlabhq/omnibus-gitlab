
module Prometheus
  class << self
    def flags_for(node, service)
      config = ""
      node['gitlab'][service]["flags"].each do |flag_key, flag_value|
        config += "-#{flag_key}=#{flag_value} " unless flag_value.empty?
      end
      config
    end
  end
end
