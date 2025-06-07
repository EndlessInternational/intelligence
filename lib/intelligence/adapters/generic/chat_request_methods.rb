module Intelligence
  module Generic
    module ChatRequestMethods

      module ClassMethods
        def chat_request_uri( uri = nil )
          if uri
            @chat_request_uri = uri
          else
            @chat_request_uri
          end
        end
      end

      CHAT_COMPLETIONS_PATH = 'chat/completions'

      def self.included( base )
        base.extend( ClassMethods )
      end

      def chat_request_uri( options = nil )
        options = merge_options( @options, build_options( options ) )
        self.class.chat_request_uri || begin 
          base_uri = options[ :base_uri ]
          if base_uri
            # because URI join is dumb
            base_uri = ( base_uri.end_with?( '/' ) ? base_uri : base_uri + '/' ) 
            URI.join( base_uri, CHAT_COMPLETIONS_PATH )
          else
            nil 
          end
        end
      end

      def chat_request_headers( options = nil )
        options = merge_options( @options, build_options( options ) )
        result = {}

        key = options[ :key ]

        raise ArgumentError.new( "An API key is required to build a chat request." ) \
          if key.nil?

        result[ 'Content-Type' ] = 'application/json'
        result[ 'Authorization' ] = "Bearer #{key}"

        result 
      end

      def chat_request_body( conversation, options = nil )
        tools = options.delete( :tools ) || []

        options = merge_options( @options, build_options( options ) )
        
        result = options[ :chat_options ]
        result[ :messages ] = []

        system_message = chat_request_system_message_attributes( conversation[ :system_message ] )
        result[ :messages ] << system_message if system_message

        conversation[ :messages ]&.each do | message |
          return nil unless message[ :contents ]&.any?

          result_message = { role: message[ :role ] }
          result_message_content = []

          message_contents = message[ :contents ]

          # tool calls in the open ai api are not content
          tool_calls, message_contents = message_contents.partition do | content | 
            content[ :type ] == :tool_call 
          end 

          # tool results in the open ai api are not content
          tool_results, message_contents = message_contents.partition do | content |
            content[ :type ] == :tool_result 
          end 

          # many vendor api's, especially when hosting text only models, will only accept a single 
          # text content item; if the content is only text this will coalece multiple text content 
          # items into a single content item
          unless message_contents.any? { | c | c[ :type ] != :text }
            result_message_content = message_contents.map { | c | c[ :text ] || '' }.join( "\n" )
          else  
            message_contents&.each do | content |
              result_message_content << chat_request_message_content_attributes( content )
            end
          end

          if tool_calls.any?
            result_message[ :tool_calls ] = tool_calls.map { | tool_call |
              {
                id: tool_call[ :tool_call_id ],
                type: 'function',
                function: {
                  name: tool_call[ :tool_name ],
                  arguments: JSON.generate( tool_call[ :tool_parameters ] || {} )
                }
              }
            }
          end 

          result_message[ :content ] = result_message_content 
          unless result_message_content.empty? && tool_calls.empty? 
           result[ :messages ] << result_message 
          end 

          if tool_results.any? 
            result[ :messages ].concat( tool_results.map { | tool_result |
              {
                role: :tool, 
                tool_call_id: tool_result[ :tool_call_id ],
                content: tool_result[ :tool_result ]
              }
            } )
          end 
        end 

        tools_attributes = chat_request_tools_attributes( 
          ( result[ :tools ] || [] ).concat( tools ) 
        )
        result[ :tools ] = tools_attributes if tools_attributes && tools_attributes.length > 0
        
        JSON.generate( result )
      end 

      def chat_request_message_content_attributes( content )
        case content[ :type ]
        when :text
          { type: 'text', text: content[ :text ] }
        when :binary 
          content_type = content[ :content_type ]
          bytes = content[ :bytes ]
          if content_type && bytes
            mime_type = MIME::Types[ content_type ].first
            if mime_type&.media_type == 'image'
              {
                type: 'image_url',
                image_url: {
                  url: "data:#{content_type};base64,#{Base64.strict_encode64( bytes )}".freeze
                }
              }
            else
              raise UnsupportedContentError.new( 
                :generic, 
                'only support content of type image/*' 
              ) 
            end
          else 
            raise UnsupportedContentError.new(
              :generic, 
              'requires binary content to include content type and ( packed ) bytes'  
            )
          end
        when :file 
          content_type = content[ :content_type ]
          uri = content[ :uri ]
          if content_type && uri
            mime_type = MIME::Types[ content_type ].first
            if mime_type&.media_type == 'image'
              {
                type: 'image_url',
                image_url: { url: uri }
              }
            else
              raise UnsupportedContentError.new( 
                :generic, 
                'only support content of type image/*' 
              ) 
            end
          else 
            raise UnsupportedContentError.new(
              :generic, 
              'requires binary content to include content type and ( packed ) bytes'  
            )
          end
        end
      end

      def chat_request_system_message_attributes( system_message )
        return nil if system_message.nil?

        result = ''
        system_message[ :contents ].each do | content |
          result += content[ :text ] if content[ :type ] == :text 
        end

        result.empty? ? nil : { role: 'system', content: result } if system_message  
      end 

      def chat_request_tools_attributes( tools ) 
        properties_array_to_object = lambda do | properties |
          return nil unless properties&.any?  
          object = {}
          required = []
          properties.each do | property | 
            name = property.delete( :name ) 
            required << name if property.delete( :required )
            if property[ :properties ]&.any?  
              property_properties, property_required = 
                properties_array_to_object.call( property[ :properties ] ) 
              property[ :properties ] = property_properties 
              property[ :required ] = property_required if property_required.any?
            end 
            object[ name ] = property 
          end 
          [ object, required.compact  ]
        end

        tools&.map do | tool |
          function = { 
            type: 'function',
            function: {
              name: tool[ :name ],
              description: tool[ :description ],
            }
          }
      
          if tool[ :properties ]&.any? 
            properties_object, properties_required = 
              properties_array_to_object.call( tool[ :properties ] ) 
            function[ :function ][ :parameters ] = {
              type: 'object',
              properties: properties_object 
            }
            function[ :function ][ :parameters ][ :required ] = properties_required \
              if properties_required.any?
          else
            function[ :function ][ :parameters ] = {}
          end
          function 
        end
      end
    
    end
  end
end
