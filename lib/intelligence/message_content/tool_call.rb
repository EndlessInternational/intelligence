module Intelligence   
  module MessageContent 

    class ToolCall < Base
      
      schema do 
        tool_call_id    String 
        tool_name       String, required: true 
        tool_parameters [ Hash, String ]
      end 

      attribute         :tool_call_id, :tool_name

      def tool_parameters( options = nil )
        raw = @attributes[ :tool_parameters ]
        
        return raw \
          if raw.nil? || 
             raw.is_a?( Hash ) ||
             ( raw.is_a?( String ) && raw.empty? )
        
        options = options || {}
        parse = options.key?( :parse ) ? options[ :parse ] : true 

        return @parsed_tool_parameters if @parsed_tool_parameters && parse 
        
        tool_parameters = begin 
          if ( parse && ( options.key?( :repair ) ? options[ :repair ] : true ) )
            JSON.repair( raw )
          else 
            raw 
          end
        rescue JSON::JSONRepairError
          raw
        end

        if parse 
          begin 
            @parsed_tool_parameters = tool_parameters = 
              JSON.parse( 
                tool_parameters, 
                parse.is_a?( Hash ) ? parse : { symbolize_names: true } 
              )
          rescue JSON::ParserError
          end 
        end

        tool_parameters 
      end

      def valid?
        tool_name && !tool_name.empty?
      end

      def to_h
        super.merge( tool_parameters: tool_parameters )
      end

    end 

  end
end