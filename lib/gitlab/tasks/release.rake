namespace :release do
  desc "Release omnibus package"
  task package: ["check:on_tag", "build:project", "build:package:sync"]

  desc "Release docker image"
  task docker: ["docker:pull:staging", "docker:push:stable", "docker:push:rc", "docker:push:latest"]

  desc "Release QA image"
  task qa: ["qa:build", "qa:push:stable", "qa:push:rc", "qa:push:latest"]
end
