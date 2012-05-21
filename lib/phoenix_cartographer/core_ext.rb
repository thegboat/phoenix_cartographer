class String
  def minified!
    self.gsub!(/\s+/, ' ')
    self.squeeze!(" ")
    self
  end
end