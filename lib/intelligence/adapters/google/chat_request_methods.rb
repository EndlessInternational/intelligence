require 'uri'

module Intelligence
  module Google
    module ChatRequestMethods

      GENERATIVE_LANGUAGE_URI = "https://generativelanguage.googleapis.com/v1beta/models/"

      SUPPORTED_BINARY_MEDIA_TYPES = %w[ text ]

      SUPPORTED_BINARY_CONTENT_TYPES = %w[
        image/png image/jpeg image/webp image/heic image/heif 
        audio/aac audio/flac audio/mp3 audio/m4a audio/mpeg audio/mpga audio/mp4 audio/opus 
        audio/pcm audio/wav audio/webm
        application/pdf 
      ]

      SUPPORTED_FILE_MEDIA_TYPES = %w[ text ]

      SUPPORTED_FILE_CONTENT_TYPES = %w[
        image/png image/jpeg image/webp image/heic image/heif 
        video/x-flv video/quicktime video/mpeg video/mpegps video/mpg video/mp4 video/webm 
        video/wmv video/3gpp
        audio/aac audio/flac audio/mp3 audio/m4a audio/mpeg audio/mpga audio/mp4 audio/opus 
        audio/pcm audio/wav audio/webm
        application/pdf 
      ]

      def chat_request_uri( options )
        options = merge_options( @options, build_options( options ) )

        key = options[ :key ] 
        gc = options[ :generationConfig ] || {}
        model = gc[ :model ]
        stream = gc.key?( :stream ) ? gc[ :stream ] : false 
      
        raise ArgumentError.new( "A Google API key is required to build a Google chat request." ) \
          if key.nil?
        raise ArgumentError.new( "A Google model is required to build a Google chat request." ) \
          if model.nil?
        
        uri = URI( GENERATIVE_LANGUAGE_URI )
        path = File.join( uri.path, model )
        path += stream ? ':streamGenerateContent' : ':generateContent'
        uri.path = path
        query = { key: key }
        query[ :alt ] = 'sse' if stream
        uri.query = URI.encode_www_form( query )

        uri.to_s
      end

      def chat_request_headers( options = {} )
        { 'Content-Type' => 'application/json' }
      end

      def chat_request_body( conversation, options = {} )
        tools = options.delete( :tools ) || []
        options = merge_options( @options, build_options( options ) )

        gc = options[ :generationConfig ]&.dup || {}
        # discard properties not part of the google generationConfig schema
        gc.delete( :model )
        gc.delete( :stream )

        # googlify tools
        tools_object = gc.delete( :abilities )
        tool_functions = to_google_tools( ( gc.delete( :tools ) || [] ).concat( tools ) )

        if tool_functions&.any?
          tools_object ||= {}
          tools_object[ :function_declarations ] ||= []
          tools_object[ :function_declarations ].concat( tool_functions )
        end 

        # googlify tool configuration 
        if tool_config = gc.delete( :tool_config )
          mode = tool_config[ :function_calling_config ]&.[]( :mode )
          tool_config[ :function_calling_config ][ :mode ] = mode.to_s.upcase if mode 
        end 

        result = {}
        result[ :generationConfig ] = gc
        result[ :tools ] = tools_object if tools_object 
        result[ :tool_config ] = tool_config if tools && tool_config

        # construct the system prompt in the form of the google schema
        system_instructions = to_google_system_message( conversation[ :system_message ] )
        result[ :systemInstruction ] = system_instructions if system_instructions

        result[ :contents ] = []
        conversation[ :messages ]&.each do | message |

          result_message = { role: message[ :role ] == :user ? 'user' : 'model' }
          result_message_parts = []
          
          message[ :contents ]&.each do | content |
            case content[ :type ]
            when :text
              result_message_parts << { text: content[ :text ] }
            when :binary
              content_type = content[ :content_type ]
              bytes = content[ :bytes ]
              if content_type && bytes
                mime_type = MIME::Types[ content_type ].first
                if SUPPORTED_BINARY_MEDIA_TYPES.include?( mime_type&.media_type ) || 
                   SUPPORTED_BINARY_CONTENT_TYPES.include?( content_type )
                  result_message_parts << {
                    inline_data: {
                      mime_type: content_type,
                      data: Base64.strict_encode64( bytes )
                    }
                  }
                else
                  raise UnsupportedContentError.new( 
                    :google, 
                    "does not support #{content_type} content type"
                  ) 
                end
              else 
                raise UnsupportedContentError.new(
                  :google, 
                  'requires binary content to include content type and ( packed ) bytes'  
                )
              end 
            when :file
              content_type = content[ :content_type ]
              uri = content[ :uri ]
              if content_type && uri
                mime_type = MIME::Types[ content_type ].first
                if SUPPORTED_FILE_MEDIA_TYPES.include?( mime_type&.media_type ) || 
                   SUPPORTED_FILE_CONTENT_TYPES.include?( content_type )
                  result_message_parts << {
                    file_data: {
                      mime_type: content_type,
                      file_uri: uri
                    }
                  }
                else
                  raise UnsupportedContentError.new( 
                    :google, 
                    "does not support #{content_type} content type"
                  ) 
                end
              else 
                raise UnsupportedContentError.new(
                  :google, 
                  'requires file content to include content type and uri'  
                )
              end 
            when :tool_call
              result_message_parts << { 
                functionCall: {
                  name: content[ :tool_name ],
                  args: content[ :tool_parameters ]
                }
              }
            when :tool_result 
              result_message_parts << {
                functionResponse: {
                  name: content[ :tool_name ],
                  response: {
                    name: content[ :tool_name ],
                    content: content[ :tool_result ]
                  } 
                }
              }
            else 
              raise InvalidContentError.new( :google ) 
            end 
          end

          result_message[ :parts ] = result_message_parts
          result[ :contents ] << result_message

        end 

        JSON.generate( result )
      end 

    private 
    
      def to_google_system_message( system_message )
        return nil if system_message.nil?

        text = ''
        system_message[ :contents ].each do | content |
          text += content[ :text ] if content[ :type ] == :text 
        end

        return nil if text.empty?

        {
          role: 'user',
          parts: [
            { text: text }
          ] 
        }
      end 

      def to_google_tools( tools ) 
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

        return tools&.map { | tool |
          function = { 
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
            function[ :parameters ][ :required ] = properties_required if properties_required.any?
          end
          function 
        } 
      end

    end

  end

end
