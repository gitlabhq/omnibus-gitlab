templatesymlink 'sample template' do
  link_from '/opt/gitlab/embedded/service/gitlab-rails/config/database.yml'
  link_to '/var/opt/gitlab/gitlab-rails/etc/database.yml'
  source 'test-template.erb'
  variables(value: 500)
end
