# gitlab Cookbook (CE)

Configures the different components needed for an Omnibus installation of GitLab

## Resources

### database_objects

Utility resource to configure user, database and resources for running GitLab

#### properties

* `pg_helper`: The helper object for interacting with the running database. Required
* `account_helper`: The helper object for handling OS accounts. Required

### puma_config

Generate puma.rb configuration file

#### properties

* `filename`: (name_property): Full path to the configuration file to be generated
* `tag`: Additonal text to display on process listing. Default: `gitlab-puma-worker`
* `rackup`: Name of the rackup configuration file. Default: `config.ru`
* `environment`: App server environment to run the app. Default: `production`
* `install_dir`: Base omnibus installation directory. Default: `node['package']['install-dir']`
* `listen_socket`: Full path of the socket to listen on. Optional
* `listen_tcp`: TCP address and port to listen on. Optional
* `working_directory`: Directory to run puma from. Optional
* `worker_timeout`: Puma worker timeout. Default: `60`
* `per_worker_max_memory_mb`: Puma max memory per worker (in MB). Optional
* `worker_processes, Integer`: Puma number of worker process. Default: `2`
* `min_threads`: Puma min number of threads. Default: `4`
* `max_threads`: Puma max number of threads. Default: `4`
* `pid`: Puma full path to create PID file. Optional
* `state_path`: Puma full path to where state files will be stored. Optional
* `stderr_path`: Puma stderr path. Optional
* `stdout_path`: Puma stdout path. Optional 
* `owner`: User owning configuration files. Default: `root`
* `group`: Group owning configuration files. Default: `root`
* `mode`: Filesystem permission flags. Default: `0644`
* `dependent_services`: List of dependent services that will need to be restarted. Optional
* `cookbook`: Cookbook from where the template will be fetched

### sidekiq_service

Configure runit service for running sidekiq

#### properties

* `rails_app`: Rails app setting passed to runit options. Default: `gitlab-rails`
* `user`: System user who will own the runit service. Default: `node['gitlab']['user']['username']`
* `group`: System group who will own the runit service. Default: `node['gitlab']['user']['group']`
* `log_directory`: Path to where runit will store logs for this service. Optional
* `template_name`: Runit template name. Default: `sidekiq`
