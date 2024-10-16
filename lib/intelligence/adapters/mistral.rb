require_relative 'legacy/adapter'

module Intelligence
  module Mistral

    class Adapter < Legacy::Adapter

      chat_request_uri "https://api.mistral.ai/v1/chat/completions"
      
      configuration do 
        parameter :key, String 
        group :chat_options do 
          parameter :model, String
          parameter :temperature, Float
          parameter :top_p, Float
          parameter :max_tokens, Integer
          parameter :min_tokens, Integer
          parameter :seed, Integer, as: :random_seed 
          parameter :stop, String, array: true
          parameter :stream, [ TrueClass, FalseClass ]

          parameter :random_seed, Integer
          group :response_format do 
            parameter :type, String 
          end
          group :tool_choice do 
            parameter :type, String 
            group :function do 
              parameter :name, String 
            end
          end
        end
      end

    end

  end
end
