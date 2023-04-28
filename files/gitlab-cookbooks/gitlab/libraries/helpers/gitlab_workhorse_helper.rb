require_relative 'base_helper'

class GitlabWorkhorseHelper < BaseHelper
  attr_reader :node

  def unix_socket?
    node['gitlab']['gitlab_workhorse']['listen_network'] == "unix"
  end

  def object_store_toml
    object_store = node['gitlab']['gitlab_rails']['object_store']

    return unless object_store['enabled']

    case object_store.dig('connection', 'provider')
    when 'AWS'
      <<~AWSCFG
      [object_storage]
        provider = "AWS"
      [object_storage.s3]
        aws_access_key_id = #{toml_string(object_store.dig('connection', 'aws_access_key_id'))}
        aws_secret_access_key = #{toml_string(object_store.dig('connection', 'aws_secret_access_key'))}
      AWSCFG
    when 'AzureRM'
      <<~AZURECFG
      [object_storage]
        provider = "AzureRM"
      [object_storage.azurerm]
        azure_storage_account_name = #{toml_string(object_store.dig('connection', 'azure_storage_account_name'))}
        azure_storage_access_key = #{toml_string(object_store.dig('connection', 'azure_storage_access_key'))}
      AZURECFG
    when 'Google'
      google_config_from(object_store)
    end
  end

  private

  def toml_string(str)
    (str || '').to_json
  end

  def google_config_from(object_store)
    connection = object_store['connection']

    return unless connection['google_application_default'] ||
      connection['google_json_key_string'] ||
      connection['google_json_key_location']

    result = <<~GOOGLECFG
    [object_storage]
      provider = "Google"
    GOOGLECFG

    if connection['google_application_default']
      value = connection['google_application_default']
      result << <<~GOOGLECFG
      [object_storage.google]
        google_application_default = #{toml_string(value)}
      GOOGLECFG
    elsif connection['google_json_key_string']
      value = connection['google_json_key_string']
      result << <<~GOOGLECFG
      [object_storage.google]
        google_json_key_string = '''#{value}'''
      GOOGLECFG
    elsif connection['google_json_key_location']
      value = connection['google_json_key_location']
      result << <<~GOOGLECFG
      [object_storage.google]
        google_json_key_location = #{toml_string(value)}
      GOOGLECFG
    end

    result
  end
end
