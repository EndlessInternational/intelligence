module Intelligence   
  module MessageContent 

    class ToolResult < Base

      schema do 
        tool_call_id
        tool_name       String, required: true 
        tool_result     [ Hash, String ]
      end 

      attr_reader :tool_call_id 
      attr_reader :tool_name
      attr_reader :tool_result

      def valid?
        tool_call_id && !tool_call_id.empty? &&
        tool_name && !tool_name.empty?
      end

      def to_h
        { 
          type:             :tool_result, 
          tool_call_id:     tool_call_id, 
          tool_name:        tool_name, 
          tool_result:      tool_result 
        }.compact
      end
      
    end 

  end
end
