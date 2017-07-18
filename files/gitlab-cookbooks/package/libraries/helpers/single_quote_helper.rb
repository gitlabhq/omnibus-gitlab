module SingleQuoteHelper
  def single_quote(string)
    "'#{string}'" unless string.nil?
  end
end
