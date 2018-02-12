if defined?(ChefSpec)
  ChefSpec.define_matcher :templatesymlink

  def create_templatesymlink(message)
    ChefSpec::Matchers::ResourceMatcher.new(:templatesymlink, :create, message)
  end

  # postgresql_database custom resource matchers
  ChefSpec.define_matcher :postgresql_database

  def create_postgresql_database(owner)
    ChefSpec::Matchers::ResourceMatcher.new(:postgresql_database, :create, owner)
  end
end
