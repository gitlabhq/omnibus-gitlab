# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.for_project(self) do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins

  gitlab_dangerfiles.import_dangerfiles(except: %w[simple_roulette])
end
