# frozen_string_literal: true
# vi: ft=ruby

require 'gitlab-dangerfiles'

# Documentation reference: https://gitlab.com/gitlab-org/ruby/gems/gitlab-dangerfiles
Gitlab::Dangerfiles.for_project(self, 'omnibus-gitlab') do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins

  gitlab_dangerfiles.config.files_to_category = {
    %r{\Adoc/} => [:docs],
    %r{\ADangerfile} => [:build],
    %r{\AGemfile} => [:build],
    %r{\AGemfile.lock} => [:build],
    %r{\Aomnibus.rb} => [:build],
    %r{\AOMNIBUS_GEM_VERSION} => [:build],
    %r{\ARakefile} => [:build],
    %r{\Aconfig/} => [:build],
    %r{\Adanger/} => [:build],
    %r{\Adocker/} => [:build],
    %r{\Agitlab-ci-config/} => [:build],
    %r{\Alib/} => [:build],
    %r{\Aresources/} => [:build],
    %r{\Ascripts/} => [:build],
    %r{\Asupport/} => [:build],
    %r{\Aspec/lib/} => [:build],
    %r{\Aletsencrypt-test/} => [:configure],
    %r{\Afiles/} => [:configure],
    %r{\Aspec/chef/} => [:configure]
  }

  gitlab_dangerfiles.config.custom_labels_for_categories = {
    build: '~"Category:Build"',
    docs: '~"docs"',
    configure: '~"Category:Configuration'
  }

  gitlab_dangerfiles.import_dangerfiles
end
