module Intelligence
  module Adapter
    module ClassMethods

      def build( options = nil, &block )
        self.new( configuration: self.build_with_schema( options, &block ) )
      end

      def build!( options = nil, &block )
        self.new( configuration: self.build_with_schema!( options, &block ) ) 
      end

    end
  end
end
