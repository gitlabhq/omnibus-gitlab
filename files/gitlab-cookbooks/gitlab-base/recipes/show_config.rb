# This is here so that tests can use `gitlab-base::show_config` recipe
# so that all the necessary cookbooks will get loaded

include_recipe "package::show_config"
