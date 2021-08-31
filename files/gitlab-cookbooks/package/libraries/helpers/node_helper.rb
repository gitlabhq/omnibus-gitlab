# frozen_string_literal: true

module NodeHelper
  def self.consume_cluster_attributes(node, attrs)
    node.logger.debug("Applying attributes from Gitlab Cluster configuration")
    node.override_attrs = merge_override!(node.override_attrs, attrs)
  end

  def self.merge_override!(first, second)
    first = Mash.new(first) unless first.is_a?(Mash)
    second = Mash.new(second) unless second.is_a?(Mash)

    deep_merge_override!(Chef::Mixin::DeepMerge.safe_dup(first), Chef::Mixin::DeepMerge.safe_dup(second.dup))
  end

  def self.deep_merge_override!(source, dest, parent = [])
    # if dest doesn't exist, then simply copy source to it
    if dest.nil?
      dest = source

      return dest
    end

    case source
    when nil
      dest
    when Hash
      if dest.is_a?(Hash)
        source.each do |src_key, src_value|
          dest[src_key] = if dest.key?(src_key)
                            deep_merge_override!(src_value, dest[src_key], parent.dup.append(src_value))
                          else
                            # dest[src_key] doesn't exist so we take whatever source has
                            src_value
                          end
        end
      else
        # dest isn't a hash, so we overwrite it completely
        dest = source
      end
    when Array
      if dest.is_a?(Array)
        GitlabCluster.log_overriding_message(parent, source)
        dest |= source
      else
        dest = source
      end
    when String
      GitlabCluster.log_overriding_message(parent, source)
      dest = source
    else
      # src_hash is not an array or hash, so we'll have to overwrite dest
      GitlabCluster.log_overriding_message(parent, source)
      dest = source
    end

    dest
  end
end
