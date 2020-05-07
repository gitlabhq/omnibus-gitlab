runit_service 'foo' do
end

version_file 'Test version file creation' do
  version_file_path '/tmp/VERSION_TEST'
  version_check_cmd 'echo 1.0.0-test'
  notifies :hup, "runit_service[foo]"
end
