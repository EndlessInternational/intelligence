require_relative 'chat_request_methods'
require_relative 'chat_response_methods'

module Intelligence
  module Anthropic
    class Adapter < Adapter::Base

      schema do 

        # normalized properties for all endpoints
        key 

        # anthropic specific properties for all endpoints
        version           String, default: '2023-06-01'
 
        chat_options do 
  
          # normalized properties for anthropic generative text endpoint
          model           String
          max_tokens      Integer, in: (1...)
          temperature     Float, in: 0.0..1.0 
          top_k           Integer, in: (1...)
          top_p           Float, in: (0..1)
          stop            String, array: true, as: :stop_sequences
          stream          [ TrueClass, FalseClass ]

          # anthropic variant of normalized properties for anthropic generative text endpoints
          stop_sequences  String, array: true

          # antropic reasoning
          thinking        do 
            type          required: true, default: 'enabled'
            budget_tokens required: true, in: (1024...)
          end

          # anthropic specific properties for anthropic generative text endpoints
          tool            array: true, as: :tools, &Tool.schema 
          # anthropic tool choice configuration; note that there is no 'none' option so if 
          # tools are provided :auto will be the default
          #
          # `tool_choice :any` 
          # or 
          # ```
          # tool_choice :tool do 
          #   function :my_tool 
          # end  
          # ```
          tool_choice     arguments: :type do 
            type          Symbol, in: [ :any, :auto, :tool ]  
            # the name parameter should only be set if type = 'tool'
            name          String
          end
          
          container       String
          metadata do
            user_id       String
          end           
          service_tier    Symbol, in: [ :auto, :standard_only ]

        end
        
      end

      include ChatRequestMethods
      include ChatResponseMethods

    end 
  end
end

