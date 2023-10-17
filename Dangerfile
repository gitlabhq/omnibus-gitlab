# frozen_string_literal: true

require 'gitlab-dangerfiles'

# Documentation reference: https://gitlab.com/gitlab-org/ruby/gems/gitlab-dangerfiles
Gitlab::Dangerfiles.for_project(self, 'omnibus-gitlab') do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins

  gitlab_dangerfiles.import_dangerfiles
end
