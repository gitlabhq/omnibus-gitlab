# All tasks in files placed in lib/gitlab/tasks ending in .rake will be loaded
# automatically
require 'knapsack'
Rake.add_rakelib 'lib/gitlab/tasks'
Knapsack.load_tasks

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['-D', 'config', 'lib', 'spec', 'files/gitlab-ctl-commands', 'files/gitlab-cookbooks/gitlab-ee']
end
