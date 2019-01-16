module Rubocop
  module Cop
    class AvoidUsingEnv < RuboCop::Cop::Cop
      MSG_GET = 'Do not use ENV directly to retrieve environment variables. Use Gitlab::Util.get_env method instead.'.freeze
      MSG_SET = 'Do not use ENV directly to set environment variables, use Gitlab::Util.set_env or Gitlab::Util.set_env_if_missing methods instead.'.freeze

      def_node_matcher :env_or_assignment?, <<~PATTERN
        (or_asgn (send (const nil? :ENV) :[] (str ...)) ...)
      PATTERN

      def_node_matcher :env_retreival?, <<~PATTERN
        (send (const nil? :ENV) :[] (str ...))
      PATTERN

      def_node_matcher :env_assignment?, <<~PATTERN
        (send (const nil? :ENV) :[]= ...)
      PATTERN

      def on_or_asgn(node)
        add_offense(node, location: :expression, message: MSG_SET) if env_or_assignment?(node)
      end

      def on_send(node)
        if env_retreival?(node)
          add_offense(node, location: :expression, message: MSG_GET)
        elsif env_assignment?(node)
          add_offense(node, location: :expression, message: MSG_SET)
        end
      end

      def autocorrect(node)
        if env_or_assignment?(node)
          key = node.children[0].children[2].source
          value = node.children[1].source
          lambda do |corrector|
            corrector.replace(node.loc.expression, set_env_if_missing(key, value))
          end
        elsif env_retreival?(node)
          lambda do |corrector|
            corrector.replace(node.loc.expression, get_env(env_key(node)))
          end
        elsif env_assignment?(node)
          lambda do |corrector|
            corrector.replace(node.loc.expression, set_env(env_key(node), env_val(node)))
          end
        end
      end

      def env_key(node)
        node.children[2].source
      end

      def env_val(node)
        node.children[3].source
      end

      def get_env(key)
        "Gitlab::Util.get_env(#{key})"
      end

      def set_env(key, val)
        "Gitlab::Util.set_env(#{key}, #{val})"
      end

      def set_env_if_missing(key, val)
        "Gitlab::Util.set_env_if_missing(#{key}, #{val})"
      end
    end
  end
end
