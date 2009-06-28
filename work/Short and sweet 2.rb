class Chars
  def initialize(string)
    @wrapped_string = string
  end
  
  def upcase
    self.class.new(GLib::g_utf8_strup(@wrapped_string))
  end
  
  def upcase!
    @wrapped_string.replace(GLib::g_utf8_strup(@wrapped_string))
  end
  
  def method_missing(m, *a, &b)
    result = @wrapped_string.send(m, *a, &b)
    if result.kind_of?(String)
      self.class.new(result)
    else
      result
    end
  end
end

class String
  def chars
    Chars.new(self)
  end
end