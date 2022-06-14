crond_job 'letsencrypt-renew' do
  action :delete
  user "root"
  command "/opt/gitlab/bin/gitlab-ctl renew-le-certs"
end
