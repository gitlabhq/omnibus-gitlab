# All tasks in files placed in lib/gitlab/tasks ending in .rake will be loaded
# automatically
require 'knapsack'
Rake.add_rakelib 'lib/gitlab/tasks'
Knapsack.load_tasks

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |t|

  # This will be removed once everything is made Rubocop friendly.
  t.options = ['-D', 'config',
               'lib',
               'spec',
               'support',
               'files/gitlab-ctl-commands',
               'files/gitlab-cookbooks/gitlab-ee',
               'files/gitlab-cookbooks/runit',
               'files/gitlab-cookbooks/package',
               'files/gitlab-cookbooks/registry',
               'files/gitlab-cookbooks/gitaly',
               'files/gitlab-cookbooks/postgresql',
               'files/gitlab-cookbooks/repmgr',
               'files/gitlab-cookbooks/mattermost',
               'files/gitlab-cookbooks/gitlab/attributes',
               'files/gitlab-cookbooks/gitlab/definitions',
               'files/gitlab-cookbooks/gitlab/templates']
end
