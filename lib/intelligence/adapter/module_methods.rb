module Intelligence
  module Adapter
    module ModuleMethods

      def []( adapter_type )

        raise ArgumentError.new( "An adapter type is required but nil was given." ) \
          if adapter_type.nil?

        class_name = adapter_type.to_s.split( '_' ).map( &:capitalize ).join
        class_name += "::Adapter"

        adapter_class = Intelligence.const_get( class_name ) rescue nil
        if adapter_class.nil?
          adapter_file = File.expand_path( "../../adapters/#{adapter_type}", __FILE__ )
          unless require adapter_file
            raise ArgumentError.new( 
              "The Intelligence adapter file #{adapter_file} is missing or does not define #{class_name}." 
            )
          end
          adapter_class = Intelligence.const_get( class_name ) rescue nil
        end

        raise ArgumentError.new( "An unknown Intelligence adapter #{adapter_type} was requested." ) \
          if adapter_class.nil? 

        adapter_class

      end

      def build( adapter_type, attributes = nil, &block )
        self.[]( adapter_type ).build( attributes, &block )
      end

      def build!( adapter_type, attributes = nil, &block )
        self.[]( adapter_type ).build!( attributes, &block )
      end

    end
  end
end  
