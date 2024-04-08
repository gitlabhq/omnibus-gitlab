module Rubocop
  module Cop
    class SpecifyDefaultVersion < RuboCop::Cop::Base
      NOTICE_REGEXP = '^ *default_version'.freeze
      MSG = 'Specify default_version for the component.'.freeze

      def on_new_investigation
        return if notice_found?(processed_source)

        add_global_offense(format(MSG))
      end

      private

      def notice_found?(processed_source)
        notice_regexp = Regexp.new(NOTICE_REGEXP)

        notice_found = false
        processed_source.lines.each do |line|
          notice_found = notice_regexp.match?(line)
          break if notice_found
        end

        notice_found
      end
    end
  end
end
