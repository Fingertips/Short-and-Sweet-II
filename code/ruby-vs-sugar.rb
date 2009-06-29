class Base
end

module Wrong
  module Kewl
    def is_uber_kewl!
      include InstanceMethods
    end
    
    module InstanceMethods
      def foo
      end
    end
  end
  Base.extend Kewl
  
  class IsKewl < Base
    is_uber_kewl!
  end
end

module Good
  module AlsoKewlButMaybeABitLess
    def foo
    end
  end
  
  class IsKewlButMaybeABitLess < Base
    include AlsoKewlButMaybeABitLess
  end
end

module Wrong
  module ProvidesClassMethods
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end
    
    module ClassMethods
      def foo
      end
    end
  end
  
  class IsHidingExtend
    include ProvidesClassMethods
  end
end

module Good
  module ClassMethods
    def foo
    end
  end
  
  class IsNotHidingExtend
    extend ClassMethods
  end
end