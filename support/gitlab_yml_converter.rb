# This script translates settings from a gitlab.yml file to the format of
# omnibus-gitlab's /etc/gitlab/gitlab.rb file.
#
# The output is NOT a valid gitlab.rb file! The purpose of this script is only
# to reduce copy and paste work.
#
# Usage: ruby gitlab_yml_converter.rb /path/to/gitlab.yml

require 'yaml'

module GitlabYamlConverter
  class Flattener
    def initialize(separator = '_')
      @separator = separator
    end

    def flatten(hash, prefix = nil)
      Enumerator.new do |yielder|
        hash.each do |key, value|
          raise "Bad key: #{key.inspect}" unless key.is_a?(String)

          key = [prefix, key].join(@separator) if prefix

          if value.is_a?(Hash)
            flatten(value, key).each do |nested_key_value|
              yielder.yield nested_key_value
            end
          else
            yielder.yield [key, value]
          end
        end
      end
    end
  end

  def self.convert(gitlab_yml)
    Flattener.new.flatten(gitlab_yml['production']).each do |key, value|
      puts "gitlab_rails['#{key}'] = #{value.inspect}"
    end
  end
end

GitlabYamlConverter.convert(YAML.safe_load(ARGF.read)) if $PROGRAM_NAME == __FILE__
