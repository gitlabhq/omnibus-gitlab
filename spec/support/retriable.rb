# frozen_string_literal: true

require 'retriable'

Retriable.configure do |c|
  c.base_interval = 0
  c.sleep_disabled = true
end
