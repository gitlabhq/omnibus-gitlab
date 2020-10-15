require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/geo/promotion_preflight_checks"

add_command_under_category('promotion-preflight-checks', 'gitlab-geo', 'Run preflight checks for promotion to primary node', 2) do |cmd_name, *args|
  def get_ctl_options
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: gitlab-ctl promotion-preflight-checks [options]"

      opts.on('-p', '--[no-]confirm-primary-is-down', 'Do not ask for confirmation that primary is down') do |p|
        options[:confirm_primary_is_down] = p
      end
    end.parse!(ARGV.dup)

    options
  end

  Geo::PromotionPreflightChecks.new(base_path, get_ctl_options).execute
end
