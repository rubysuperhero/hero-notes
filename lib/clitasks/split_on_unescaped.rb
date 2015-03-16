class String
  def split_on_unescaped(str)
    self.split(/\s*(?<!\\)#{str}\s*/).map{|s| s.gsub(/\\(?=#{str})/, '') }
  end
end
