require_relative 'build/check'

# This module has tests in spec/gitlab/build_iteration_spec.rb
module Gitlab
  class BuildIteration
    def initialize(git_describe = nil)
      @git_describe = git_describe || `git describe`
      @git_describe = @git_describe.chomp
    end

    def build_iteration
      if Build::Check.on_tag?
        match = /[^+]*\+([^\-]*)/.match(@git_describe)
        if match && !match[1].empty?
          result = match[1]
          result = result.gsub('ee.', 'fips.') if Build::Check.use_system_ssl?

          return result
        end
      end

      # For any builds other than a tag release, built_iteration value is not of
      # much use. If not here, we would have to add this check in project
      # definition as well as for docker builds. It is easier to simply use 0
      # for non-release builds.
      '0'
    end
  end
end
