module LoggingHelper
  extend self

  # The current set of recorded messages.  Mostly here to enable more fluent spec
  # testing.
  #
  # @return [Array<Hash{Symbol => String, nil}>]
  attr_accessor :messages
  @messages = []

  # Resets the set of recorded messages.  Mostly here to enable more fluent spec
  # testing.
  #
  # @return [void]
  def reset
    @messages = []
  end

  # Records a message the user should be informed of later.
  #
  # @param message [String] A message to give the user
  # @param kind: [:deprecation, nil]
  # @return [void]
  def log(message, kind: nil)
    @messages << {
      message: message,
      kind: kind
    }
  end

  # Records a message as deprecation, logging as we see it.
  #
  # @param message [String] A message to give the user
  # @return [void]
  def deprecation(message)
    Chef::Log.warn message
    log(message, kind: :deprecation)
  end

  # Reports on the actions the user should take
  #
  # @return [true]
  def report
    deprecations = @messages.select { |m| m[:kind] == :deprecation }

    if deprecations.any?
      puts
      puts "Deprecations:"
      puts

      messages = deprecations.map { |m| m[:message] }
      puts messages.join("\n---\n\n")
      puts
    end

    # code blocks in chef report callbacks are expected to yield true
    true
  end
end
