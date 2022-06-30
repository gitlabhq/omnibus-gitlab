require_relative 'base_helper'

class GitlabWorkhorseHelper < BaseHelper
  attr_reader :node

  def unix_socket?
    node['gitlab']['gitlab-workhorse']['listen_network'] == "unix"
  end

  def object_store_toml
    object_store = node['gitlab']['gitlab-rails']['object_store']

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
    end
  end

  def toml_string(str)
    (str || '').to_json
  end
end
