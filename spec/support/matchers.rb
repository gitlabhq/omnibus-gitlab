ChefSpec.define_matcher :postgresql_user

def create_postgresql_user(password)
  ChefSpec::Matchers::ResourceMatcher.new(:postgresql_user, :create, password)
end
