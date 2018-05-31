require_relative 'base_helper'

class GitlabRailsHelper < BaseHelper
  attr_accessor :node

  def public_attributes
    {
      'gitlab' => {
        'gitlab-rails' => node['gitlab']['gitlab-rails'].select do |key, value|
          %w(db_database).include?(key)
        end
      }
    }
  end
end
