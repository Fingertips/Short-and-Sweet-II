require 'rubygems'
require 'activesupport'
require 'netaddr'

require File.expand_path('../composed_of', __FILE__)
require File.expand_path('../attribute-views', __FILE__)

# A simple implementation of ActiveRecord::Base which provides enough to run
# the examples.
module ActiveRecord
  class Base
    extend Aggregations
    extend AttributeViews
    
    def initialize(attributes = nil)
      self.attributes = attributes if attributes
    end
    
    def attributes=(attributes)
      attributes.each do |attr, value|
        self[attr] = value
      end
    end
    
    def [](attr)
      ensure_attr!(attr)
      send(attr)
    end
    alias_method :read_attribute, :[]
    
    def []=(attr, value)
      ensure_attr!(attr)
      send("#{attr}=", value)
    end
    
    private
    
    def ensure_attr!(attr)
      self.class.class_eval { attr_accessor(attr) } unless respond_to?(attr)
    end
  end
end

def inspect_resource(resource)
  p resource
  p resource.cidr
  puts
end