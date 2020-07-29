crond_job 'letsencrypt-renew' do
  action :delete
end

include_recipe "crond::disable"
