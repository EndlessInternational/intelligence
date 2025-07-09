module Intelligence
  module OpenAi
    module ChatRequestMethods

      CHAT_COMPLETIONS_PATH = 'responses'
      SUPPORTED_CONTENT_TYPES = [ 'image/jpeg', 'image/png', 'image/webp' ]

      def chat_request_uri( options = nil )
        options = merge_options( @options, build_options( options ) )
        base_uri = options[ :base_uri ]
        if base_uri
          # because URI join is dumb
          base_uri = ( base_uri.end_with?( '/' ) ? base_uri : base_uri + '/' ) 
          URI.join( base_uri, CHAT_COMPLETIONS_PATH )
        else
          raise 'The OpenAI adapter requires a base_uri.' 
        end
      end

      def chat_request_headers( options = {} )
        options = merge_options( @options, build_options( options ) )
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

        tools = options.delete( :tools ) || []
        # open ai abilities are essentially custom tools; when passed as an option they should
        # be in the open ai tool format ( which is essentially just a hash where the type is 
        # the custome tool name )   
        #
        #  {
        #    abilities: [
        #      { type: 'web_search_preview' },
        #      { type: 'image_generation', background: 'transparent' },
        #      { type: 'local_shell' } 
        #    ]
        #  } 
        abilities = options.delete( :abilities ) || []

        options = merge_options( @options, build_options( options ) )
        result = options[ :chat_options ]&.compact || {}
        result[ :input ] = []

        system_message = to_open_ai_system_message( conversation[ :system_message ] )
        result[ :instructions ] = system_message if system_message

        conversation[ :messages ]&.each do | message |
         
          result_message = nil          
          message[ :contents ]&.each do | content |
            case content[ :type ]
            when :text
              result_message = { role: message[ :role ], content: [] } if result_message.nil?
              result_message[ :content ] << { 
                type: ( message[ :role ] == :user ? 'input_text' : 'output_text' ), 
                text: content[ :text ] 
              }
            when :binary
              result_message = { role: message[ :role ], content: [] } if result_message.nil?
              content_type = content[ :content_type ]
              bytes = content[ :bytes ]
              if content_type && bytes
                if SUPPORTED_CONTENT_TYPES.include?( content_type )
                  result_message[ :content ] << {
                    type: ( message[ :role ] == :user ? 'input_image' : 'output_image' ), 
                    image_url: "data:#{content_type};base64,#{Base64.strict_encode64( bytes )}".freeze
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
              result_message = { role: message[ :role ], content: [] } if result_message.nil?
              content_type = content[ :content_type ]
              uri = content[ :uri ]
              if content_type && uri  
                if SUPPORTED_CONTENT_TYPES.include?( content_type )
                  result_message[ :content ] << {
                    type: ( message[ :role ] == :user ? 'input_image' : 'output_image' ), 
                    image_url: uri 
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
              if result_message
                result[ :input ] << result_message
                result_message = nil 
              end
              result[ :input ] << {
                type: 'function_call',
                call_id: content[ :tool_call_id ],
                name: content[ :tool_name ],
                arguments: JSON.generate( content[ :tool_parameters ] || {} )
              } 
            when :tool_result 
              if result_message
                result[ :input ] << result_message
                result_message = nil 
              end
              result[ :input ] << {
                type: 'function_call_output',
                call_id: content[ :tool_call_id ],
                output: content[ :tool_result ]
              }
            else 
              raise InvalidContentError.new( :open_ai ) 
            end

          end

          result[ :input ] << result_message if result_message

        end
 
        tools_attributes = chat_request_tools_attributes( 
          ( result[ :tools ] || [] ).concat( tools ) 
        )
        abilities.concat( result.delete( :abilities )&.values || [] )
        tools_attributes.concat( abilities ) 

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

        Utilities.deep_dup( tools )&.map do | tool |
          function = { 
            type: 'function',
            name: tool[ :name ],
            description: tool[ :description ],
          }
      
          if tool[ :properties ]&.any? 
            properties_object, properties_required = 
              properties_array_to_object.call( tool[ :properties ] ) 
            function[ :parameters ] = {
              type: 'object',
              properties: properties_object 
            }
            function[ :parameters ][ :required ] = properties_required \
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
