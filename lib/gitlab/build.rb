require_relative "util"

module Build
  def self.log_level
    if Gitlab::Util.get_env('BUILD_LOG_LEVEL') && !Gitlab::Util.get_env('BUILD_LOG_LEVEL').empty?
      Gitlab::Util.get_env('BUILD_LOG_LEVEL')
    else
      'info'
    end
  end

  def self.exec(project)
    system(*cmd(project))
  end

  def self.cmd(project)
    %W[bundle exec omnibus build #{project} --log-level #{log_level}]
  end
end
