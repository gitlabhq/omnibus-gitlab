# This module has tests in spec/gitlab/build_iteration_spec.rb

module Gitlab
  class BuildIteration
    def initialize(git_describe=nil)
      @git_describe = git_describe || `git describe`
      @git_describe = @git_describe.chomp
    end

    def build_iteration
      match = /[^+]*\+([^\-]*)/.match(@git_describe)
      if match && !match[1].empty?
        match[1]
      else
        '0'
      end
    end
  end
end
