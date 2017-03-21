class Build
  class << self
    include FileUtils

    def exec(project)
      sh cmd(project)
    end

    def cmd(project)
      "bundle exec omnibus build #{project} --log-level #{log_level}"
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
