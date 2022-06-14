crond_job 'delete' do
  action :delete
  user "rspec"
  command "echo 'Hello world'"
end
