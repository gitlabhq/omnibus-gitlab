module AuthorizeHelper
  def query_gitlab_rails(uri, name, oauth_uid, oauth_secret)
    warn("Connecting to GitLab to generate new app_id and app_secret for #{name}.")
    runner_cmd = create_or_find_authorization(uri, name, oauth_uid, oauth_secret)
    cmd = execute_rails_runner(runner_cmd)
    do_shell_out(cmd)
  end

  def create_or_find_authorization(uri, name, oauth_uid, oauth_secret)
    args = %(redirect_uri: "#{uri}", name: "#{name}")

    app = %(
      app = Doorkeeper::Application.where(#{args}).by_uid_and_secret("#{oauth_uid}", "#{oauth_secret}");
      app ||= Doorkeeper::Application.where({ redirect_uri: "#{uri}", name: "#{name}", uid: "#{oauth_uid}", secret: "#{oauth_secret}" }).create!
    )

    output = %(puts app.uid.concat(" ").concat(app.secret);)

    %W(
      #{app}
      #{output}
    ).join
  end

  def execute_rails_runner(cmd)
    %W(
      /opt/gitlab/bin/gitlab-rails
      runner
      -e production
      '#{cmd}'
    ).join(" ")
  end

  def warn(msg)
    Chef::Log.warn(msg)
  end

  def info(msg)
    Chef::Log.info(msg)
  end
end
