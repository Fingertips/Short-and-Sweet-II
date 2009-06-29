# Original copy at: http://github.com/rails/rails/blob/master/activerecord/lib/active_record/aggregations.rb

module ActiveRecord
  module Aggregations # :nodoc:
    extend ActiveSupport::Concern

    def clear_aggregation_cache #:nodoc:
      self.class.reflect_on_all_aggregations.to_a.each do |assoc|
        instance_variable_set "@#{assoc.name}", nil
      end unless self.new_record?
    end

    # For example, the NetworkResource model has +network_address+ and
    # +cidr_range+ attributes that should be aggregated using the NetAddr::CIDR
    # value class (http://netaddr.rubyforge.org). The constructor for the value
    # class is called +create+ and it expects a CIDR address string as a
    # parameter. New values can be assigned to the value object using either
    # another NetAddr::CIDR object, a string or an array. The
    # <tt>:constructor</tt> and <tt>:converter</tt> options can be used to meet
    # these requirements:
    #
    #   class NetworkResource < ActiveRecord::Base
    #     composed_of :cidr,
    #                 :class_name  => 'NetAddr::CIDR',
    #                 :mapping     => [ %w(network_address network), %w(cidr_range bits) ],
    #                 :allow_nil   => true,
    #                 :constructor => Proc.new { |network_address, cidr_range|
    #                   NetAddr::CIDR.create("#{network_address}/#{cidr_range}")
    #                 },
    #                 :converter   => Proc.new { |value|
    #                   NetAddr::CIDR.create(value.is_a?(Array) ? value.join('/') : value)
    #                 }
    #   end
    #
    # This calls the constructor:
    #
    #   network_resource = NetworkResource.new(:network_address => '192.168.0.1', :cidr_range => 24)
    #
    # These assignments will both use the converter:
    #
    #   network_resource.cidr = [ '192.168.2.1', 8 ]
    #   network_resource.cidr = '192.168.0.1/24'
    #
    # This assignment won't use the :converter as the value is already an
    # instance of the value class:
    #
    #   network_resource.cidr = NetAddr::CIDR.create('192.168.2.1/8')
    #
    # Saving and then reloading will use the :constructor on reload:
    #
    #   network_resource.save
    #   network_resource.reload
    module ClassMethods
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

        create_reflection(:composed_of, part_id, options, self)
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
end