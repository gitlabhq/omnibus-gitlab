# Just the basic rspec configuration common to all spec testing.
# Use this if you do not need the full weight of `chef_helper`

require 'rubocop'
require 'fantaskspec'
require 'knapsack'
require 'gitlab/util'
require 'rspec-parameterized'

# Load support libraries to provide common convenience methods for our tests
Dir["./spec/support/**/*.rb"].each { |f| require f }

$LOAD_PATH << './files/gitlab-ctl-commands-ee/lib'
$LOAD_PATH << './files/gitlab-ctl-commands/lib'

Knapsack::Adapters::RSpecAdapter.bind if Gitlab::Util.get_env('USE_KNAPSACK')
Knapsack.report.config({
                         test_file_pattern: 'spec/chef/**/*_spec.rb'
                       })

RSpec.configure do |config|
  config.example_status_persistence_file_path = './spec/examples.txt' unless Gitlab::Util.get_env('CI')
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.include(GitlabSpec::Macros)
  config.include(GitlabSpec::Expectations)

  config.disable_monkey_patching!
end
