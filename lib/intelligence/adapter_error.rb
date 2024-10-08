module Intelligence 
  class AdapterError < Error;
    def initialize( adapter_type, text )
      adapter_class_name = adapter_type.to_s.split( '_' ).map( &:capitalize ).join
      super( "The #{adapter_class_name} #{text}." )
    end
  end 
end
