# To be used in tests. We can't directly converge on `package::config` becaues
# `package` cookbook does not define any dependencies, and thus the libraries
# in service cookbooks won't run and won't populate any default values. This is
# precisely why we have a `gitlab-base` cookbook.

include_recipe 'package::config'
