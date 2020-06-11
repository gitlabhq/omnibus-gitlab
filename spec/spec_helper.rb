# Just the basic rspec configuration common to all spec testing.
# Use this if you do not need the full weight of `chef_helper`

require 'fantaskspec'
require 'knapsack'
require 'gitlab/util'
require 'rspec-parameterized'

# Load support libraries to provide common convenience methods for our tests
Dir["./spec/support/**/*.rb"].each { |f| require f }

$LOAD_PATH << './files/gitlab-ctl-commands-ee/lib'
$LOAD_PATH << './files/gitlab-ctl-commands/lib'

Knapsack::Adapters::RSpecAdapter.bind if Gitlab::Util.get_env('USE_KNAPSACK')

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.include(GitlabSpec::Macros)
  config.include ExpectOffense
end
