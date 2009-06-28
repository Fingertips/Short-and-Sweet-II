class Handler
  class << self
    def upcase(string)
      GLib::g_utf8_strup(string)
    end
  end
end

class Chars
  def self.handler=(handler)
    @handler = handler
  end
  
  def self.handler; @handler; end
  
  def initialize(string)
    @wrapped_string = string
  end
  
  def method_missing(m, *a, &b)
    if self.class.handler.respond_to(m)
      result = self.class.handler.send(m, *a, &b)
      if result.kind_of?(String)
        if m.to_s =~ /^(.*)!$/
          @wrapped_string.replace(result)
        else
          self.class.new(result)
        end
      else
        result
      end
    else
      @wrapped_string.send(m, *a, &b)
    end
  end
end

Chars.handler = Handler

class String
  def chars
    Chars.new(self)
  end
end