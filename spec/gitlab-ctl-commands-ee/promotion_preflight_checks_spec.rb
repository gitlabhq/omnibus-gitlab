require 'spec_helper'
require 'geo/promotion_preflight_checks'

describe 'gitlab-ctl promotion-preflight-checks' do
  include_examples 'gitlab geo commands',
                   'promotion-preflight-checks',
                   Geo::PromotionPreflightChecks,
                   'promotion_preflight_checks'
end
