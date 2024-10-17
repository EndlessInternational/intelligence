require_relative 'chat_methods'

module Intelligence
  module OpenAi
    class Adapter < Adapter::Base

      configuration do 

        # normalized properties for all endpoints
        parameter :key, String
        
        # openai properties for all endpoints
        parameter :organization
        parameter :project
        
        # properties for generative text endpoints
        group :chat_options do 
        
          # normalized properties for openai generative text endpoint
          parameter :model, String
          parameter :n, Integer
          parameter :max_tokens, Integer, as: :max_completion_tokens
          parameter :temperature, Float
          parameter :top_p, Float
          parameter :seed, Integer
          parameter :stop, String, array: true
          parameter :stream, [ TrueClass, FalseClass ]

          parameter :frequency_penalty, Float
          parameter :presence_penalty, Float

          # openai variant of normalized properties for openai generative text endpoints
          parameter :max_completion_tokens, Integer

          # openai properties for openai generative text endpoint
          parameter :logit_bias
          parameter :logprobs, [ TrueClass, FalseClass ]
          parameter :modalities, String, array: true 
          parameter :parallel_tool_calls, [ TrueClass, FalseClass ]
          group :response_format do 
            # 'text' and 'json_schema' are the only supported types
            parameter :type, String
            parameter :json_schema
          end
          parameter :service_tier, String
          group :stream_options do
            parameter :include_usage, [ TrueClass, FalseClass ]
          end
          parameter :tool_choice
          # the parallel_tool_calls parameter is only allowed when 'tools' are specified
          parameter :top_logprobs, Integer
          parameter :user

        end

      end

      include ChatMethods

    end 
  end
end
