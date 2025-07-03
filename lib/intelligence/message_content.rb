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

    def self.merge( this_contents, that_contents )
      this_contents  ||= []
      that_contents ||= []

      length = [ this_contents.size, that_contents.size ].max

      Array.new( length ) do | index |
        
        this_content = this_contents[ index ] 
        that_content = that_contents[ index ]

        if this_content && that_content              
          this_content.merge( that_content )
        else                    
          this_content || that_content
        end
      end
    end

  end
end

