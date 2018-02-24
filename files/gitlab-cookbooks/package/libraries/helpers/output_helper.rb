require 'awesome_print'

module OutputHelper
  def quote(string)
    string.to_s.inspect unless string.nil?
  end

  def print_ruby_object(object)
    object.ai(plain: true)
  end
end
