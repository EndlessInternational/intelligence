module Intelligence
  module Utilities
    def deep_dup( object )
      case object
        when Hash
          object.each_with_object( { } ) do | ( key, value ), target |
            target[ key ] = deep_dup( value )
          end
        when Array
          object.map { | element | deep_dup( element ) }
        else
          object
        end    
    end

    module_function :deep_dup
  end
end