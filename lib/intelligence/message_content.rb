Dir[ File.join( __dir__, 'message_content', '*.rb' ) ].each do | file |
  require_relative file
end

module Intelligence   
  module MessageContent 
   
    def self.[]( type ) 
      type_name = type.to_s.split( '_' ).map { | word | word.capitalize }.join
      klass = Intelligence.const_get( "MessageContent::#{type_name}" ) rescue nil
      raise TypeError, "An unknown content type '#{type}' was given." unless klass
      klass
    end

    def self.build!( type, attributes = nil, &block )
      self[ type ].build!( attributes, &block )
    end
    
    def self.build( type, attributes = nil, &block )
      self[ type ].build( attributes, &block )
    end

  end
end

