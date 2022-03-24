require 'chef_helper'
require 'geo/promotion_preflight_checks'

RSpec.shared_context 'promotion-preflight-checks' do
  let(:command_name) { 'promotion-preflight-checks' }
  let(:klass) { Geo::PromotionPreflightChecks }
  let(:command_script) { 'promotion_preflight_checks' }
end

RSpec.describe 'gitlab-ctl promotion-preflight-checks' do
  include_context 'promotion-preflight-checks'
  include_context 'ctl'

  it_behaves_like 'gitlab geo promotion commands'

  it_behaves_like 'geo promotion command accepts option',
                  '--confirm-primary-is-down',
                  { confirm_primary_is_down: true }
end
