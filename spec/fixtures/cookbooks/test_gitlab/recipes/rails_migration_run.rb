ruby_block 'test-dependent' do
  true
end

rails_migration 'gitlab-test' do
  migration_task 'gitlab:db:configure'
  migration_logfile_prefix 'gitlab-test-db-migrate'
  migration_helper RailsMigrationHelper.new(node)

  dependent_services ["ruby_block[test-dependent]"]
end
