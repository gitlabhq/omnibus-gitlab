# frozen_string_literal: true

module NodeHelper
  def self.consume_cluster_attributes(node, attrs)
    node.logger.debug("Applying attributes from Gitlab Cluster configuration")
    node.override_attrs = merge_override!(node.override_attrs, attrs)
  end

  def self.merge_override!(source, dest)
    message = "The configured values from #{GitlabCluster::JSON_FILE} overrides the " \
              "the setting in the /etc/gitlab/gitlab.rb configuration file"

    LoggingHelper.warning(message) unless dest.empty?

    Chef::Mixin::DeepMerge.merge(source, dest)
  end
end
