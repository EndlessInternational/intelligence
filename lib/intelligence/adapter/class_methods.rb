module Intelligence
  module Adapter
    module ClassMethods

      def build( options = nil, &block )
        new( configuration: builder.build( options, &block ) )
      end

      def build!( options = nil, &block )
        new( configuration: builder.build( options, &block ) )
      end

    end
  end
end
