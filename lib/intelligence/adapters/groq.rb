require_relative 'generic/adapter'

module Intelligence
  module Groq

    class Adapter < Generic::Adapter
      
      DEFAULT_BASE_URI        = 'https://api.groq.com/openai/v1'

      schema do 

        base_uri              String, default: DEFAULT_BASE_URI
        key                   String
        
        chat_options do 

          frequency_penalty   Float
          logit_bias
          logprobs            [ TrueClass, FalseClass ]
          max_tokens          Integer
          model               String
          # the parallel_tool_calls is only allowed when 'tools' are specified
          parallel_tool_calls [ TrueClass, FalseClass ]
          presence_penalty    Float
          response_format do 
            # 'text' and 'json_object' are the only supported types; you must also instruct 
            # the model to output json
            type              Symbol, in: [ :text, :json_object ]
          end
          seed                Integer
          stop                String, array: true
          
          stream              [ TrueClass, FalseClass ]
          stream_options do
            include_usage     [ TrueClass, FalseClass ]
          end

          temperature         Float
          tool                array: true, as: :tools, &Tool.schema 
          tool_choice         String
        
          top_logprobs        Integer
          top_p               Float
          user                String
        
        end

      end

    end

  end
end
