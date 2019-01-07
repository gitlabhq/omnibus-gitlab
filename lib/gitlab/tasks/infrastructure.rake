desc 'Infrastructure maintenance tasks and utilities'

namespace :infrastructure do
  # Use this task to add/update `known_hosts` file, in the unlikely case of a change in
  # `gitlab.com` and `dev.gitlab.org` SSH keys.
  # Note: After running this task you need to add and commit `support/known_hosts`.
  desc 'Updates the known SSH hosts used in CI config'
  task :known_hosts do
    gitlab_hosts = %w(gitlab.com dev.gitlab.org)
    system('ssh-keyscan', *gitlab_hosts, out: 'support/known_hosts')
  end
end
