# frozen_string_literal: true

require 'spec_helper'
require 'geo/promote_to_primary_node'

describe 'gitlab-ctl promote-to-primary-node' do
  let(:klass) { Geo::PromoteToPrimaryNode }
  let(:command_name) { 'promote-to-primary-node' }
  let(:command_script) { 'promote_to_primary_node' }

  include_context 'ctl'

  it_behaves_like 'gitlab geo promotion commands', 'promote-to-primary-node'

  it_behaves_like 'geo promotion command accepts option',
                  '--confirm-primary-is-down',
                  { confirm_primary_is_down: true }

  it_behaves_like 'geo promotion command accepts option',
                  '--skip-preflight-checks',
                  { skip_preflight_checks: true }

  it_behaves_like 'geo promotion command accepts option',
                  '--force',
                  { force: true }
end
