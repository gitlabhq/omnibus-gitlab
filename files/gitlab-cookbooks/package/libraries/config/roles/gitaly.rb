module GitalyRole
  def self.load_role
    return unless Gitlab['gitaly_role']['enable']

    # Turning off GitLab Rails unless explicitly enabled.
    Gitlab['gitlab_rails']['enable'] ||= false

    Services.enable_group('gitaly_role')
  end
end
