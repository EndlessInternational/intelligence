require_relative 'chat_request_methods'
require_relative 'chat_response_methods'

module Intelligence
  module OpenAi
    class Adapter < Adapter::Base

      schema do 

        # normalized properties for all endpoints
        key                         String
        
        # openai properties for all endpoints
        organization                String 
        project                     String 
        
        # properties for generative text endpoints
        chat_options do 
        
          # normalized properties for openai generative text endpoint
          model                     String, requried: true 
          n                         Integer
          max_tokens                Integer, as: :max_completion_tokens
          temperature               Float
          top_p                     Float
          seed                      Integer
          stop                      String, array: true
          stream                    [ TrueClass, FalseClass ]

          frequency_penalty         Float
          presence_penalty          Float

          # openai variant of normalized properties for openai generative text endpoints
          max_completion_tokens     Integer

          # openai properties for openai generative text endpoint
          audio do 
            voice                   String 
            format                  String 
          end
          logit_bias
          logprobs                  [ TrueClass, FalseClass ]
          top_logprobs              Integer
          modalities                String, array: true 
          response_format do 
            # 'text' and 'json_schema' are the only supported types
            type                    Symbol, in: [ :text, :json_schema ]
            json_schema
          end
          service_tier              String
          stream_options do
            include_usage           [ TrueClass, FalseClass ]
          end
          user 
          
          # open ai tools
          tool                      array: true, as: :tools, &Tool.schema 
          # open ai tool choice configuration 
          #
          # `tool_choice :none` 
          # or 
          # ```
          # tool_choice :function do 
          #   function :my_function 
          # end  
          # ```
          tool_choice               arguments: :type do 
            type                    Symbol, in: [ :none, :auto, :required ]
            function                arguments: :name do 
              name                  Symbol 
            end 
          end 
          # the parallel_tool_calls parameter is only allowed when 'tools' are specified
          parallel_tool_calls       [ TrueClass, FalseClass ]

        end

      end

      include ChatRequestMethods 
      include ChatResponseMethods

    end 
  end
end
