property :title, String, name_property: true
property :user, String, required: true
property :minute, [String, Integer], default: "*"
property :hour, [String, Integer], default: "*"
property :day_of_month, [String, Integer], default: "*"
property :month, [String, Integer], default: "*"
property :day_of_week, [String, Integer], default: "*"
property :command, String, required: true

action :create do
  schedule = [
    new_resource.minute,
    new_resource.hour,
    new_resource.day_of_month,
    new_resource.month,
    new_resource.day_of_week,
  ].join(" ")

  file "#{node['go-crond']['cron_d']}/#{new_resource.title}" do
    owner "root"
    group "root"
    content "#{schedule} #{new_resource.user} #{new_resource.command}\n"
    notifies :restart, 'service[go-crond]' if node['go-crond']['enable']
    only_if { node['go-crond']['enable'] }
  end
end

action :delete do
  file "#{node['go-crond']['cron_d']}/#{new_resource.title}" do
    action :delete
    notifies :restart, 'service[go-crond]' if node['go-crond']['enable']
  end
end
