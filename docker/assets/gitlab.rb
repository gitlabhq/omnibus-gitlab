# Docker options
## Prevent Postgres from trying to allocate 25% of total memory
postgresql['shared_buffers'] = '1MB'

# Manage accounts with docker
manage_accounts['enable'] = false

# Get hostname from shell
host = `hostname`.strip
external_url "http://#{host}"

# Load /etc/gitlab/gitlab.rb
from_file("/etc/gitlab/gitlab.rb")
