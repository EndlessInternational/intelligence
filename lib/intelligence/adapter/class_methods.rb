module Intelligence
  module Adapter
    module ClassMethods

      def build( options = nil, &block )
        self.new( configuration: self.configure( options, &block ) )
      end

      def build!( options = nil, &block )
        self.new( configuration: self.configure!( options, &block ) ) 
      end

    end
  end
end
