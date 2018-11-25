require_relative "build/info.rb"

module Build
  def self.exec(project)
    system(*cmd(project))
  end

  def self.cmd(project)
    %W[bundle exec omnibus build #{project} --log-level #{Info.log_level}]
  end
end
