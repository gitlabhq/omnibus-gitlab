if defined?(ChefSpec)
  def create_template_symlink(message)
    ChefSpec::Matchers::ResourceMatcher.new(:gitlab_template_symlink, :create, message)
  end
end
