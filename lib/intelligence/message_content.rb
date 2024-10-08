Dir[ File.join( __dir__, 'message_content', '*.rb' ) ].each do | file |
  require_relative file
end

module Intelligence   
  module MessageContent 
    
    def self.build( type, attributes )
      type_name = type.to_s.split( '_' ).map { | word | word.capitalize }.join
      klass = Intelligence.const_get( "MessageContent::#{type_name}" ) rescue nil
      klass.nil? ? nil : klass.new( attributes )
    end

  end
end

