require_relative 'legacy/adapter'

module Intelligence
  module Groq

    class Adapter < Legacy::Adapter
      
      chat_request_uri 'https://api.groq.com/openai/v1/chat/completions'

      configuration do 
        parameter :key, String
        group :chat_options do 
          parameter :frequency_penalty, Float
          parameter :logit_bias
          parameter :logprobs, [ TrueClass, FalseClass ]
          parameter :max_tokens, Integer
          parameter :model, String
          parameter :n, Integer
            # the parallel_tool_calls parameter is only allowed when 'tools' are specified
          parameter :parallel_tool_calls, [ TrueClass, FalseClass ]
          parameter :presence_penalty, Float
          group :response_format do 
            # 'text' and 'json_object' are the only supported types; you must also instruct 
            # the model to output json
            parameter :type, String
          end
          parameter :seed, Integer
          parameter :stop, String, array: true
          parameter :stream, [ TrueClass, FalseClass ]
          group :stream_options do
            parameter :include_usage, [ TrueClass, FalseClass ]
          end
          parameter :temperature, Float
          group :tool_choice do 
            # one of 'auto', 'none' or 'function'
            parameter :type, String 
            # the function group is required if you specify a type of 'function' 
            group :function do 
              parameter :name, String 
            end
          end
          parameter :top_logprobs, Integer
          parameter :top_p, Float
          parameter :user, String
        end
      end

    end

  end
end
