require_relative 'generic/adapter'

module Intelligence
  module Mistral
    class Adapter < Generic::Adapter

      chat_request_uri "https://api.mistral.ai/v1/chat/completions"
      
      schema do 
        key                   String 
        chat_options do 
          model               String
          temperature         Float
          top_p               Float
          max_tokens          Integer
          min_tokens          Integer
          seed                Integer, as: :random_seed 
          stop                String, array: true
          stream              [ TrueClass, FalseClass ]

          random_seed         Integer
          response_format do 
            type              String 
          end

          tool                array: true, as: :tools, &Tool.schema 
          tool_choice do 
            type              String 
            function do 
              name            String 
            end
          end
        end
      end
    
    end
  end
end
