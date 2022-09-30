# frozen_string_literal: true

require 'retriable'

Retriable.configure do |config|
  # Retry with exponential backoff, for a maximum of ~6 minutes
  #
  # Ideal for waiting for package publish to succeed.
  config.contexts[:package_publish] = {
    base_interval: 5,
    tries: 10
  }
end
