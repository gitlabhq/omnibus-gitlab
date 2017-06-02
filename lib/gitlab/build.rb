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

    private

    def log_level
      if ENV['BUILD_LOG_LEVEL'] && !ENV['BUILD_LOG_LEVEL'].empty?
        ENV['BUILD_LOG_LEVEL']
      else
        'info'
      end
    end
  end
end
