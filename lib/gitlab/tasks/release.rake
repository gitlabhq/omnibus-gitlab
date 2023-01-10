require_relative '../gitlab_release_helper'

namespace :release do
  desc "Release omnibus package"
  task package: ["check:on_tag", "build:project", "build:package:sync"]

  desc "Release docker image"
  task docker: ["docker:pull:staging", "docker:push:stable", "docker:push:rc", "docker:push:latest"]

  desc "Release QA image"
  # For downstream users like JiHu to retain original behavior
  qa_release_tasks = if Gitlab::Util.get_env("BUILD_GITLAB_QA_IMAGE") == "true"
                       ["qa:build", "qa:push:stable", "qa:push:rc", "qa:push:latest"]
                     else
                       ["qa:copy:stable", "qa:copy:rc", "qa:copy:latest"]
                     end
  task qa: qa_release_tasks

  desc "Create GitLab release"
  task :print_details do
    puts GitlabReleaseHelper.release_details
  end
end
