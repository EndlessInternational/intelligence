module Intelligence   
  module MessageContent 

    class Base
      include DynamicSchema::Definable 

      class << self 

        def attribute( *names )
          names.each do | name |
            define_method( name ) { @attributes[ name ] }
          end
        end

        def type
          @type ||= begin
            _type = name.split( '::' ).last.dup
            _type.gsub!( /([A-Z]+)([A-Z][a-z])/, '\1_\2' )
            _type.gsub!( /([a-z\d])([A-Z])/, '\1_\2' )
            _type.tr!( '-', '_' )
            _type.downcase!
            _type.to_sym
          end
        end

        def build( attributes = nil, &block )
          new( ( attributes || {} ).merge( builder.build( attributes, &block ) ) )
        end

        def build!( attributes = nil, &block )
          new( ( attributes || {} ).merge( builder.build!( attributes, &block ) ) )
        end

      end

      def initialize( attributes = nil )
        @attributes = {}
        attributes = attributes.except( :type ) if attributes
        attributes&.each { | key, value | @attributes[ key.to_sym ] = value.freeze }
      end

      def valid?
        false
      end

      def []( key )
        @attributes[ key.to_sym ]
      end

      def type
        self.class.type
      end

      def to_h
        { type: type }.merge( @attributes ).compact
      end
    end

  end
end