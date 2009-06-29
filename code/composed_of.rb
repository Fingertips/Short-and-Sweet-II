# Original copy at: http://github.com/rails/rails/blob/master/activerecord/lib/active_record/aggregations.rb

module ActiveRecord
  module Aggregations # :nodoc:
    def composed_of(part_id, options = {}, &block)
      options.assert_valid_keys(:class_name, :mapping, :allow_nil, :constructor, :converter)

      name        = part_id.id2name
      class_name  = options[:class_name]  || name.camelize
      mapping     = options[:mapping]     || [ name, name ]
      mapping     = [ mapping ] unless mapping.first.is_a?(Array)
      allow_nil   = options[:allow_nil]   || false
      constructor = options[:constructor] || :new
      converter   = options[:converter]   || block

      ActiveSupport::Deprecation.warn('The conversion block has been deprecated, use the :converter option instead.', caller) if block_given?

      reader_method(name, class_name, mapping, allow_nil, constructor)
      writer_method(name, class_name, mapping, allow_nil, converter)

      # create_reflection(:composed_of, part_id, options, self)
    end

    private
      def reader_method(name, class_name, mapping, allow_nil, constructor)
        module_eval do
          define_method(name) do |*args|
            force_reload = args.first || false
            if (instance_variable_get("@#{name}").nil? || force_reload) && (!allow_nil || mapping.any? {|pair| !read_attribute(pair.first).nil? })
              attrs = mapping.collect {|pair| read_attribute(pair.first)}
              object = case constructor
                when Symbol
                  class_name.constantize.send(constructor, *attrs)
                when Proc, Method
                  constructor.call(*attrs)
                else
                  raise ArgumentError, 'Constructor must be a symbol denoting the constructor method to call or a Proc to be invoked.'
                end
              instance_variable_set("@#{name}", object)
            end
            instance_variable_get("@#{name}")
          end
        end
      end

      def writer_method(name, class_name, mapping, allow_nil, converter)
        module_eval do
          define_method("#{name}=") do |part|
            if part.nil? && allow_nil
              mapping.each { |pair| self[pair.first] = nil }
              instance_variable_set("@#{name}", nil)
            else
              unless part.is_a?(class_name.constantize) || converter.nil?
                part = case converter
                  when Symbol
                   class_name.constantize.send(converter, part)
                  when Proc, Method
                    converter.call(part)
                  else
                    raise ArgumentError, 'Converter must be a symbol denoting the converter method to call or a Proc to be invoked.'
                  end
              end
              mapping.each { |pair| self[pair.first] = part.send(pair.last) }
              instance_variable_set("@#{name}", part.freeze)
            end
          end
        end
      end
  end
end