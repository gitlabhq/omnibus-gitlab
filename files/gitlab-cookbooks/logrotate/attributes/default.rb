default['logrotate']['enable'] = false
default['logrotate']['ha'] = false
default['logrotate']['dir'] = "/var/opt/gitlab/logrotate"
default['logrotate']['log_directory'] = "/var/log/gitlab/logrotate"
default['logrotate']['services'] = %w(nginx puma actioncable unicorn gitlab-rails gitlab-shell gitlab-workhorse gitlab-pages gitlab-kas gitaly)
default['logrotate']['pre_sleep'] = 600 # sleep 10 minutes before rotating after start-up
default['logrotate']['post_sleep'] = 3000 # wait 50 minutes after rotating
