# Original copy at: http://github.com/Fingertips/attribute-views/blob/master/lib/active_record/attribute_views.rb

module ActiveRecord
  class AttributeView
    attr_accessor :attributes
    
    def initialize(*attributes)
      self.attributes = attributes
    end
    
    def get(record)
      load(*attributes.map { |attribute| record.send(attribute) })
    end
    
    def load(*values)
      raise NoMethodError, "Please implement the `load' method on your view class"
    end
    
    def set(record, input)
      parsed = Array(parse(input))
      record.attributes = Hash[*attributes.zip(parsed).flatten]
    end
    
    def parse(input)
      raise NoMethodError, "Please implement the `parse' method on your view class"
    end
  end
  
  module AttributeViews
    def views(name, options={})
      options.assert_valid_keys(:as)
      raise ArgumentError, "Please specify a view object with the :as option" unless options.has_key?(:as)
      
      view_name = "#{name}_view"
      
      define_method(view_name) do
        options[:as]
      end
      
      class_eval <<-READER_METHODS, __FILE__, __LINE__
        def #{name}                                       # def starts_at
          #{view_name}.get(self)                          #   starts_at_view.get(self)
        end                                               # end
      READER_METHODS
      
      class_eval <<-WRITER_METHODS, __FILE__, __LINE__
        def #{name}_before_type_cast                      # def starts_at_before_type_cast
          @#{name}_before_type_cast || #{name}            #   @starts_at_before_type_cast || starts_at
        end                                               # end
        
        def #{name}=(value)                               # def starts_at=(value)
          @#{name}_before_type_cast = value               #   @starts_at_before_type_cast = value
          #{view_name}.set(self, value)                   #   starts_at_view.set(self, value)
        end                                               # end
      WRITER_METHODS
    end
  end
end