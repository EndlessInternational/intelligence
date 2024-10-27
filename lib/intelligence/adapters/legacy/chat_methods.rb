module Intelligence
  module Legacy
    module ChatMethods

      def chat_request_body( conversation, options = {} )
        options = @options.merge( to_options( options ) )

        result = options[ :chat_options ]&.compact || {}
        result[ :messages ] = []

        system_message = system_message_to_s( conversation[ :system_message ] )
        result[ :messages ] << { role: 'system', content: system_message } if system_message
        
        # detect if the conversation has any non-text content; this handles the sittuation 
        # where non-vision models only support the legacy message schema while the vision 
        # models only support the modern message schema 
        has_non_text_content = conversation[ :messages ]&.find do | message |
          message[ :contents ]&.find do | content |
            content[ :type ] != nil && content[ :type ] != :text 
          end
        end
        
        if has_non_text_content
          conversation[ :messages ]&.each do | message |
            result[ :messages ] << chat_request_message_attributes( message )
          end
        else 
          conversation[ :messages ]&.each do | message |
            result[ :messages ] << chat_request_legacy_message_attributes( message )
          end
        end
        JSON.generate( result )
      end 

      def chat_request_legacy_message_attributes( message )
        result_message = { role: message[ :role ] }
        result_message_content = ""
        
        message[ :contents ]&.each do | content |
          case content[ :type ]
          when :text
            result_message_content += content[ :text ]
          end
        end

        result_message[ :content ] = result_message_content
        result_message
      end

    end
  end
end

