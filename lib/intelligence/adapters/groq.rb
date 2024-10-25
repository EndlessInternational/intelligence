require_relative 'legacy/adapter'

module Intelligence
  module Groq

    class Adapter < Legacy::Adapter
      
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

      alias chat_request_generic_message_attributes chat_request_message_attributes 
      
      # groq models only support the legacy Open AI message schema for the assistant 
      # messages while supporting the modern message schema for user messages 
      def chat_request_message_attributes( message )
        role = message[ :role ]&.to_sym 
        case role 
        when :user 
          chat_request_generic_message_attributes( message )
        when :assistant 
          chat_request_legacy_message_attributes( message )
        else 
          raise UnsupportedContentError.new(
            :mistral, 
            'only supports user and assistant message roles'  
          )
        end
      end

    end

  end
end
