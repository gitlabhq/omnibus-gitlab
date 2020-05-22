require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/geo/promotion_preflight_checks"

add_command_under_category('promotion-preflight-checks', 'gitlab-geo', 'Run preflight checks for promotion to primary node', 2) do |cmd_name|
  Geo::PromotionPreflightChecks.new.execute
end
