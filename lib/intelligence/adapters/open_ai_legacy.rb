require_relative 'generic/adapter'

module Intelligence
  module OpenAiLegacy
    class Adapter < Generic::Adapter

      DEFAULT_BASE_URI              = 'https://api.openai.com/v1'

      schema do 

        # normalized properties, used by all endpoints
        base_uri                    String, default: DEFAULT_BASE_URI
        key                         String
        
        # openai properties, used by all endpoints 
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

    end 
  end
end
