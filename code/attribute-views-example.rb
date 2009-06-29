require File.expand_path('../helper', __FILE__)

module Examples
  module AttributeView
    class NetAddrView < ActiveRecord::AttributeView
      def load(network_address, cidr_range)
        NetAddr::CIDR.create("#{network_address}/#{cidr_range}")
      end
      
      def parse(value)
        case value
        when Array
          value
        when String
          value.split('/')
        when NetAddr::CIDR
          [value.ip, value.netmask[1..-1]]
        end
      end
    end
  end
end

module Examples
  module AttributeView
    class NetworkResource < ActiveRecord::Base
      views :cidr, :as => NetAddrView.new(:network_address, :cidr_range)
    end
  end
end

resource = Examples::AttributeView::NetworkResource.new(
  :network_address => '192.168.0.1', :cidr_range => 24
)
inspect_resource(resource)

resource.cidr = [ '192.168.2.1', 8 ]
inspect_resource(resource)

resource.cidr = '192.168.0.1/24'
inspect_resource(resource)

resource.cidr = NetAddr::CIDR.create('192.168.2.1/8')
inspect_resource(resource)