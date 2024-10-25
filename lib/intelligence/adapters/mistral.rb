require_relative 'legacy/adapter'

module Intelligence
  module Mistral

    class Adapter < Legacy::Adapter

      chat_request_uri "https://api.mistral.ai/v1/chat/completions"
      
      schema do 
        key                   String 
        chat_options do 
          model               String
          temperature         Float
          top_p               Float
          max_tokens          Integer
          min_tokens          Integer
          seed                Integer, as: :random_seed 
          stop                String, array: true
          stream              [ TrueClass, FalseClass ]

          random_seed         Integer
          response_format do 
            type              String 
          end
          tool_choice do 
            type              String 
            function do 
              name            String 
            end
          end
        end
      end

      alias chat_request_generic_message_attributes chat_request_message_attributes 
      
      # mistral vision models only support the legacy Open AI message schema for the assistant 
      # messages while supporting the modern message schema for user messages :facepalm:
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
