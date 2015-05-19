module Gitlab
  class BuildIteration
    def initialize(git_describe=nil)
      @git_describe = git_describe || `git describe`
    end

    def build_iteration
      match = /\+[^.]*.(\d+)$/.match(@git_describe)
      if match
        match[1].to_i
      else
        0
      end
    end
  end
end
