module Intelligence   
  module MessageContent 

    class Base
      include DynamicSchema::Definable 
      include DynamicSchema::Buildable 

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

