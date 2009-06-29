require File.expand_path('../helper', __FILE__)

module Examples
  module ComposedOf
    class NetworkResource < ActiveRecord::Base
      composed_of :cidr,
                  :class_name  => 'NetAddr::CIDR',
                  :mapping     => [ %w(network_address network), %w(cidr_range bits) ],
                  :allow_nil   => true,
                  :constructor => Proc.new { |network_address, cidr_range|
                    NetAddr::CIDR.create("#{network_address}/#{cidr_range}")
                  },
                  :converter   => Proc.new { |value|
                    NetAddr::CIDR.create(value.is_a?(Array) ? value.join('/') : value)
                  }
    end
  end
end

resource = Examples::ComposedOf::NetworkResource.new(
  :network_address => '192.168.0.1', :cidr_range => 24
)
inspect_resource(resource)

resource.cidr = [ '192.168.2.1', 8 ]
inspect_resource(resource)

resource.cidr = '192.168.0.1/24'
inspect_resource(resource)

resource.cidr = NetAddr::CIDR.create('192.168.2.1/8')
inspect_resource(resource)