require_relative 'legacy/adapter'

module Intelligence
  module Cerebras

    class Adapter < Legacy::Adapter

      chat_request_uri "https://api.cerebras.ai/v1/chat/completions"
      
      configuration do 
        parameter :key 
        group :chat_options do 
          parameter :model, String
          parameter :max_tokens, Integer
          parameter :response_format do 
            parameter :type, String, default: 'json_schema'
            parameter :json_schema
          end
          parameter :seed, Integer
          parameter :stop, array: true
          parameter :stream, [ TrueClass, FalseClass ]
          parameter :temperature, Float
          parameter :top_p, Float
          parameter :tool_choice do 
            parameter :type, String 
            parameter :mame, String
          end
          parameter :user
        end
      end

    end

  end
end
