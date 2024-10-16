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
