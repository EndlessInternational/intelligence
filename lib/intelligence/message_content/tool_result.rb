module Intelligence   
  module MessageContent 

    class ToolResult < Base

      configuration do 
        parameter :tool_call_id
        parameter :tool_name, String, required: true 
        parameter :tool_result, String, required: true 
      end 

      attr_reader :tool_call_id 
      attr_reader :tool_name
      attr_reader :tool_result

      def to_h
        { 
          type:             :tool_call, 
          tool_call_id:     tool_call_id, 
          tool_name:        tool_name, 
          tool_parameters:  tool_result 
        }.compact
      end
    end 

  end
end
