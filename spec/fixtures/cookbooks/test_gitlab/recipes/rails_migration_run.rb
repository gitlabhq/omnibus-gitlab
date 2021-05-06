ruby_block 'test-dependent' do
  true
end

rails_migration 'gitlab-test' do
  rake_task 'gitlab:db:configure'
  logfile_prefix 'gitlab-test-db-migrate'
  helper RailsMigrationHelper.new(node)

  dependent_services ["ruby_block[test-dependent]"]
end
