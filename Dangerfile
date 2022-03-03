# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.for_project(self, &:import_defaults)

danger.import_dangerfile(path: 'scripts/support/metadata')
danger.import_dangerfile(path: 'scripts/support/reviewers')
danger.import_dangerfile(path: 'scripts/support/ruby_upgrade')
danger.import_dangerfile(path: 'scripts/support/software')
danger.import_dangerfile(path: 'scripts/support/specs')
danger.import_dangerfile(path: 'scripts/support/template')
