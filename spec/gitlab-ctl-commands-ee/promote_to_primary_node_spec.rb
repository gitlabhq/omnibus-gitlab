require 'spec_helper'
require 'geo/promote_to_primary_node'

describe 'gitlab-ctl promote-to-primary-node' do
  include_examples 'gitlab geo commands',
                   'promote-to-primary-node',
                   Geo::PromoteToPrimaryNode,
                   'promote_to_primary_node'
end
