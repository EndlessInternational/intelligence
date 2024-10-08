module Intelligence
  module Legacy
    module ChatMethods

      def chat_request_body( conversation, options = {} )
        options = options ? self.class.configure( options ) : {}
        options = @options.merge( options )
        result = options[ :chat_options ]&.compact || {}
        result[ :messages ] = []

        system_message = system_message_to_s( conversation[ :system_message ] )
        result[ :messages ] << { role: 'system', content: system_message } if system_message

        conversation[ :messages ]&.each do | message |
          result[ :messages ] << chat_request_message_attributes( message )
        end

        JSON.generate( result )
      end 

      def chat_request_message_attributes( message )
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

