ChefSpec.define_matcher :postgresql_user

def create_postgresql_user(password)
  ChefSpec::Matchers::ResourceMatcher.new(:postgresql_user, :create, password)
end

def create_postgresql_fdw(server_name)
  ChefSpec::Matchers::ResourceMatcher.new(:postgresql_fdw, :create, server_name)
end

def create_postgresql_fdw_user_mapping(server_name)
  ChefSpec::Matchers::ResourceMatcher.new(:postgresql_fdw_user_mapping, :create, server_name)
end

def run_postgresql_query(description)
  ChefSpec::Matchers::ResourceMatcher.new(:postgresql_query, :run, description)
end

def run_bash(description)
  ChefSpec::Matchers::ResourceMatcher.new(:bash, :run, description)
end

def enable_postgresql_extension(extension)
  ChefSpec::Matchers::ResourceMatcher.new(:postgresql_extension, :enable, extension)
end
