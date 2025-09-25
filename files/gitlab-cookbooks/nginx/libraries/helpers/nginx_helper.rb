module OmnibusGitlab
  class NginxHelper
    def initialize(node)
      @node = node
    end

    def nginx_dir
      @node['gitlab']['nginx']['dir']
    end

    def conf_dir
      File.join(nginx_dir, "conf")
    end

    def service_conf_dir
      File.join(conf_dir, "service_conf")
    end

    def upstream_definition_dir
      File.join(conf_dir, "upstream_definitions")
    end

    def extra_metrics_dir
      File.join(conf_dir, "extra_metrics_conf")
    end

    def service_conf_path(service, suffix: "conf")
      File.join(service_conf_dir, "gitlab-#{service}.#{suffix}")
    end

    def upstream_definition_conf_path(service)
      File.join(upstream_definition_dir, "#{service}.conf")
    end

    def extra_metrics_conf_path(service)
      File.join(extra_metrics_dir, "#{service}.conf")
    end
  end
end
