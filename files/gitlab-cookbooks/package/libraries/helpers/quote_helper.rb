module QuoteHelper
  def quote(string)
    string.to_s.inspect unless string.nil?
  end
end
