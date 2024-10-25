module Intelligence   
  module MessageContent 

    class Base
      extend DynamicSchema::Definition 

      def self.build( attributes = nil, &block ) 
        self.new( self.build_with_schema( attributes, &block ) )
      end 
      
      def self.build!( attributes = nil, &block ) 
        self.new( self.build_with_schema!( attributes, &block ) )
      end 
      
      def initialize( attributes = {} )
        attributes.each do | key, value |
          instance_variable_set( "@#{key}", value.freeze ) if self.respond_to?( "#{key}" )
        end
      end

      def valid?
        false
      end
    end

  end
end

