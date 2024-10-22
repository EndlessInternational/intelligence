require_relative 'chat_request_methods'
require_relative 'chat_response_methods'

module Intelligence
  module Anthropic
    class Adapter < Adapter::Base

      configuration do 

        # normalized properties for all endpoints
        parameter :key 

        # anthropic specific properties for all endpoints
        parameter :version, String, default: '2023-06-01'
 
        parameters :chat_options do 
  
          # normalized properties for anthropic generative text endpoint
          parameter :model, String
          parameter :max_tokens, Integer
          parameter :temperature, Float
          parameter :top_k, Integer
          parameter :top_p, Float
          parameter :stop, String, array: true, as: :stop_sequences
          parameter :stream, [ TrueClass, FalseClass ]

          # anthropic variant of normalized properties for anthropic generative text endpoints
          parameter :stop_sequences, String, array: true

          # anthropic specific properties for anthropic generative text endpoints
          parameter :tool_choice do 
            parameter :type, String  
            # the name parameter should only be set if type = 'tool'
            parameter :name, String
          end
          parameters :metadata do
            parameter :user_id, String
          end 
          
        end
        
      end

      include ChatRequestMethods
      include ChatResponseMethods

    end 
  end
end

