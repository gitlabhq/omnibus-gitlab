module DurationHelper
  # This code duplicates some from files/gitlab-ctl-commands/lib/gitlab_ctl/util.rb
  # because that is not easily/clearly re-usable from gitlab-cookbooks.  It might be acceptable
  # in future to link uses of the other versions to this library code (there is precedent), although
  # even that is a little surprising, and other approaches to code sharing might be better.
  # See https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9192#note_3229438233 for discussion
  DURATION_UNITS = {
    'ms' => 1,

    's' => 1000,
    'm' => 1000 * 60,
    'h' => 1000 * 60 * 60,
    'd' => 1000 * 60 * 60 * 24
  }.freeze

  def parse_duration(duration)
    millis = 0
    duration&.scan(/(?<quantity>\d+(\.\d+)?)(?<unit>[a-zA-Z]+)/)&.each do |quantity, unit|
      multiplier = DURATION_UNITS[unit]
      break if multiplier.nil?

      millis += multiplier * quantity.to_f
    end

    begin
      millis = Float(duration || '') if millis.zero?
    rescue ArgumentError
      # Translating exception
      raise ArgumentError, "invalid value for duration: `#{duration}`"
    end

    millis.to_i
  end
end
