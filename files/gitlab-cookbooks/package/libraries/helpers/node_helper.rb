# frozen_string_literal: true

module NodeHelper
  class << self
    # Merges attributes into existing node with override level
    #
    # @param [Mash] node
    # @param [Gitlab::Config::Mash] attrs
    def consume_cluster_attributes(node, attrs)
      node.logger.debug("Applying attributes from Gitlab Cluster configuration")
      node.override_attrs = merge_override!(node.override_attrs, attrs)
    end

    private

    def merge_override!(source, dest)
      message = "The configured values from #{GitlabCluster::JSON_FILE} overrides the " \
              "the setting in the /etc/gitlab/gitlab.rb configuration file"

      LoggingHelper.warning(message) unless dest.empty?
      LoggingHelper.debug("The following values will be merged from #{GitlabCluster::JSON_FILE} : #{dest.inspect}")

      Chef::Mixin::DeepMerge.merge(source, dest)
    end
  end
end
