require 'shellwords'

class CrondHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def flags
    config = []

    node['crond']['flags'].each do |flag_key, flag_value|
      next if flag_key == 'include' || flag_value == false

      config << if flag_value == true
                  "--#{flag_key}"
                elsif !flag_value.empty?
                  "--#{flag_key}=#{Shellwords.escape(flag_value)}"
                end
    end

    config << "--include=#{Shellwords.escape(node['crond']['cron_d'])}"

    config.join(" ")
  end
end
