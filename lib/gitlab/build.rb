class Build
  class << self
    include FileUtils

    def exec(project)
      sh cmd(project)
    end

    def cmd(project)
      "bundle exec omnibus build #{project} --log-level #{log_level}"
    end

    def is_ee?
      ee_env = ENV['ee']
      return true if ee_env && !ee_env.empty? && ee_env == 'true'

      system('grep -q -E "\-ee" VERSION')
    end

    def package
      return "gitlab-ee" if is_ee?

      "gitlab-ce"
    end

    # TODO, merge latest_tag with latest_stable_tag
    def latest_tag
      `git -c versionsort.prereleaseSuffix=rc tag -l '#{tag_match_pattern}' --sort=-v:refname | head -1`
    end

    def latest_stable_tag
      `git -c versionsort.prereleaseSuffix=rc tag -l '#{tag_match_pattern}' --sort=-v:refname | awk '!/rc/' | head -1`
    end

    private

    def log_level
      if ENV['BUILD_LOG_LEVEL'] && !ENV['BUILD_LOG_LEVEL'].empty?
        ENV['BUILD_LOG_LEVEL']
      else
        'info'
      end
    end

    def tag_match_pattern
      return '*[+.]ee.*' if is_ee?

      '*[+.]ce.*'
    end
  end
end
