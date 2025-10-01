module Intelligence   
  module MessageContent 
    class ToolResult < Base

      schema do 
        tool_call_id
        tool_name       String, required: true 
        tool_result     [ Hash, String ]
      end 

      attribute         :tool_call_id, :tool_name, :tool_result

      def valid?
        tool_call_id && !tool_call_id.empty? &&
        tool_name && !tool_name.empty?
      end

    end 
  end
end
