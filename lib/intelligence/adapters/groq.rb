require_relative 'generic/adapter'

module Intelligence
  module Groq

    class Adapter < Generic::Adapter

      chat_request_uri 'https://api.groq.com/openai/v1/chat/completions'

      schema do
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
          tool_choice do
            # one of 'auto', 'none' or 'function'
            type              Symbol, in: [ :auto, :none, :function ]
            # the function parameters is required if you specify a type of 'function'
            function do
              name            String
            end
          end
          top_logprobs        Integer
          top_p               Float
          user                String
        end
      end

    end

  end
end
