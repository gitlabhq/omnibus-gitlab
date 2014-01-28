name "gitlab-shell"
version "v1.8.0"

dependency "ruby"
dependency "rsync"

source :git => "https://gitlab.com/gitlab-org/gitlab-shell.git"

build do
  command "sed -i 's|^#!/usr/bin/env ruby|#!#{install_dir}/embedded/bin/ruby|' $(grep -r -l '#!/usr/bin/env ruby' .)"
  command "mkdir -p #{install_dir}/embedded/services/gitlab-shell"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/services/gitlab-shell/"
end
