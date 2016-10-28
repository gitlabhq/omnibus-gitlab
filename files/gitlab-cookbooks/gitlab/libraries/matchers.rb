if defined?(ChefSpec)
  def create_templatesymlink(message)
    ChefSpec::Matchers::ResourceMatcher.new(:templatesymlink, :create, message)
  end
end
