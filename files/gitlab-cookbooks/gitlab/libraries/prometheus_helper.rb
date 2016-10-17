
module Prometheus
  class << self
    def flags_for(node, service)
      config = []

      node['gitlab'][service]['flags'].each do |flag_key, flag_value|
        next if flag_value.empty?
        config << "-#{flag_key}=#{flag_value}"
      end

      config.join(" ")
    end
  end
end
