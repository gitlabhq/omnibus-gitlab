# frozen_string_literal: true

include_recipe 'package::sysctl'

gitlab_sysctl 'kernel.shmmax' do
  value node['postgresql']['shmmax']
end

gitlab_sysctl 'kernel.shmall' do
  value node['postgresql']['shmall']
end

sem = [
  node['postgresql']['semmsl'],
  node['postgresql']['semmns'],
  node['postgresql']['semopm'],
  node['postgresql']['semmni'],
].join(' ')
gitlab_sysctl 'kernel.sem' do
  value sem
end
