module Intelligence   
  module MessageContent 

    class ToolCall < Base
      
      configuration do 
        parameter :tool_call_id, String 
        parameter :tool_name, String, required: true 
        parameter :tool_parameters, [ Hash, String ]
      end 

      attr_reader :tool_call_id 
      attr_reader :tool_name
      attr_reader :tool_parameters

      def to_h
        { 
          type:             :tool_call, 
          tool_call_id:     tool_call_id, 
          tool_name:        tool_name, 
          tool_parameters:  tool_parameters 
        }.compact
      end
    end 

  end
end
