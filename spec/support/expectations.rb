# frozen_string_literal: true

module GitlabSpec
  module Expectations
    # Expect a note to be logged with the specified message
    #
    # @param [String] message
    # @see LoggingHelper.warning
    def expect_logged_note(message)
      expect(LoggingHelper.messages).to include(kind: :note, message: message)
    end

    # Expect a deprecation to be logged with the specified message
    #
    # @param [String] message
    # @see LoggingHelper.warning
    def expect_logged_deprecation(message)
      expect(LoggingHelper.messages).to include(kind: :deprecation, message: message)
    end

    # Expect a removal to be logged with the specified message
    #
    # @param [String] message
    # @see LoggingHelper.warning
    def expect_logged_removal(message)
      expect(LoggingHelper.messages).to include(kind: :removal, message: message)
    end

    # Expect a warning to be logged with the specified message
    #
    # @param [String] message
    # @see LoggingHelper.warning
    def expect_logged_warning(message)
      expect(LoggingHelper.messages).to include(kind: :warning, message: message)
    end
  end
end
