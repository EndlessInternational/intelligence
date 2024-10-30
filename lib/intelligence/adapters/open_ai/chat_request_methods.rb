module Intelligence
  module OpenAi
    module ChatRequestMethods

      CHAT_REQUEST_URI = "https://api.openai.com/v1/chat/completions"

      SUPPORTED_CONTENT_TYPES = [ 'image/jpeg', 'image/png' ]

      def chat_request_uri( options )
        CHAT_REQUEST_URI
      end

      def chat_request_headers( options = {} )
        options = @options.merge( build_options( options )  )
        result = {}

        key = options[ :key ] 
        organization = options[ :organization ] 
        project = options[ :project ]  

        raise ArgumentError.new( "An OpenAI key is required to build an OpenAI chat request." ) \
          if key.nil?

        result[ 'Content-Type' ] = 'application/json'
        result[ 'Authorization' ] = "Bearer #{key}"
        result[ 'OpenAI-Organization' ] = organization unless organization.nil?
        result[ 'OpenAI-Project' ] = project unless project.nil?

        result 
      end

      def chat_request_body( conversation, options = {} )
        options = @options.merge( build_options( options )  )
        result = options[ :chat_options ]&.compact || {}
        result[ :messages ] = []

        system_message = to_open_ai_system_message( conversation[ :system_message ] )
        result[ :messages ] << { role: 'system', content: system_message } if system_message

        conversation[ :messages ]&.each do | message |
         
          result_message = { role: message[ :role ] }
          result_message_content = []
          
          message[ :contents ]&.each do | content |
            case content[ :type ]
            when :text
              result_message_content << { type: 'text', text: content[ :text ] }
            when :binary
              content_type = content[ :content_type ]
              bytes = content[ :bytes ]
              if content_type && bytes
                if SUPPORTED_CONTENT_TYPES.include?( content_type )
                  result_message_content << {
                    type: 'image_url',
                    image_url: {
                      url: "data:#{content_type};base64,#{Base64.strict_encode64( bytes )}".freeze
                    }
                  }
                else
                  raise UnsupportedContentError.new( 
                    :open_ai, 
                    "only supports content of type #{SUPPORTED_CONTENT_TYPES.join( ', ' )}"
                  ) 
                end
              else 
                raise UnsupportedContentError.new(
                  :open_ai, 
                  'requires binary content to include content type and ( packed ) bytes'  
                )
              end
            when :file 
              content_type = content[ :content_type ]
              uri = content[ :uri ]
              if content_type && uri  
                if SUPPORTED_CONTENT_TYPES.include?( content_type )
                  result_message_content << {
                    type: 'image_url',
                    image_url: {
                      url: uri 
                    }
                  }
                else 
                  raise UnsupportedContentError.new( 
                    :open_ai, 
                    "only supports content of type #{SUPPORTED_CONTENT_TYPES.join( ', ' )}" 
                  ) 
                end 
              else 
                raise UnsupportedContentError.new(
                  :open_ai, 
                  'requires file content to include content type and uri'  
                )
              end 
            when :tool_call 
              tool_calls = result_message[ :tool_calls ] || [] 
              function = {
                name: content[ :tool_name ]
              }
              function[ :arguments ] = JSON.generate( content[ :tool_parameters ] || {} )
              tool_calls << { id: content[ :tool_call_id ], type: 'function', function: function }
              result_message[ :tool_calls ] = tool_calls
            when :tool_result 
              # open-ai returns tool results as a message with a role of 'tool'
              result[ :messages ] << {
                role: :tool, 
                tool_call_id: content[ :tool_call_id ],
                content: content[ :tool_result ]
              }
            else 
              raise InvalidContentError.new( :open_ai ) 
            end

          end

          result_message[ :content ] = result_message_content
          result[ :messages ] << result_message \
            if result_message[ :content ]&.any? || result_message[ :tool_calls ]&.any? 
          result

        end
 
        tools_attributes = chat_request_tools_attributes( conversation[ :tools ] )
        result[ :tools ] = tools_attributes if tools_attributes && tools_attributes.length > 0
       
        JSON.generate( result )
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
          end
          function 
        end
      end

    private 

      def to_open_ai_system_message( system_message )
        return nil if system_message.nil?

        result = ''
        system_message[ :contents ].each do | content |
          result += content[ :text ] if content[ :type ] == :text 
        end

        result.empty? ? nil : result 
      end 

    end
  end
end
