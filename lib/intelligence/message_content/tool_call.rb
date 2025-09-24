module Intelligence   
  module MessageContent 

    class ToolCall < Base
      
      schema do 
        tool_call_id    String 
        tool_name       String, required: true 
        tool_parameters [ Hash, String ]
      end 

      attr_reader :tool_call_id 
      attr_reader :tool_name

      def tool_parameters( options = nil )
        return @tool_parameters \
          if @tool_parameters.nil? || 
             @tool_parameters.is_a?( Hash ) ||
             ( @tool_parameters.is_a?( String ) && @tool_parameters.empty? )
        
        options = options || {}
        parse = options.key?( :parse ) ? options[ :parse ] : true 

        return @parsed_tool_parameters if @parsed_tool_parameters && parse 
        
        tool_parameters = begin 
          if ( options.key?( :repair ) ? options[ :repair ] : true )
            JSON.repair( @tool_parameters )
          else 
            @tool_parameters 
          end
        rescue JSON::JSONRepairError
          @tool_parameters
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

      def merge( other_tool_call ) 
        other_tool_call_id = other_tool_call.tool_call_id 
        other_tool_name = other_tool_call.tool_name 
        other_tool_parameters = other_tool_call.tool_parameters( repair: false, parse: false )
        
        raise ArgumentError, 
              "The given tool call parameters are incompative with this tool's parameters." \
          unless @tool_parameters.nil? || other_tool_parameters.nil? || 
                 @tool_parameters.is_a?( other_tool_parameters.class )
        
        tool_call_id = other_tool_call_id.nil? ? 
          @tool_call_id : @tool_call_id || '' + other_tool_call_id 
        tool_name = other_tool_name.nil? ? 
          @tool_name : @tool_name || '' + other_tool_name
        tool_parameters = @tool_parameters 

        unless other_tool_parameters.nil?
          if other_tool_parameters.is_a?( Hash )
            tool_parameters = ( tool_parameters || {} ).merge( other_tool_parameters )
          else 
            tool_parameters = ( tool_parameters || '' ) + other_tool_parameters 
          end 
        end

        self.class.new( 
          tool_call_id: tool_call_id, 
          tool_name: tool_name, 
          tool_parameters: tool_parameters 
        )
      end

      def to_h
        { 
          type:             :tool_call, 
          id:               id,
          tool_call_id:     tool_call_id, 
          tool_name:        tool_name, 
          tool_parameters:  tool_parameters 
        }.compact
      end
    end 

  end
end
