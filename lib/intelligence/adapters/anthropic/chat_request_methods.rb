module Intelligence
  module Anthropic
    module ChatRequestMethods

      CHAT_REQUEST_URI = "https://api.anthropic.com/v1/messages"

      SUPPORTED_CONTENT_TYPES = %w[ image/jpeg image/png image/gif image/webp application/pdf ]

      def chat_request_uri( options )
        CHAT_REQUEST_URI
      end

      def chat_request_headers( options = nil )
        options = merge_options( @options, build_options( options ) )
        result = {}

        key = options[ :key ] 
        version = options[ :version ] || "2023-06-01" 

        raise ArgumentError.new( 
          "An Anthropic key is required to build an Anthropic chat request." 
        ) if key.nil?

        result[ 'content-type' ] = 'application/json'
        result[ 'x-api-key' ] = "#{key}"
        result[ 'anthropic-version' ] = version unless version.nil?

        result 
      end

      def chat_request_body( conversation, options = nil )
        tools = options.delete( :tools ) || []

        options = merge_options( @options, build_options( options ) )
        result = options[ :chat_options ]&.compact || {}

        system_message = to_anthropic_system_message( conversation[ :system_message ] )
        result[ :system ] = system_message unless system_message.nil?
        result[ :messages ] = []

        messages = conversation[ :messages ] 
        length = messages&.length || 0
        index = 0; while index < length 
          
          message = messages[ index ]
          unless message.nil?

            # The Anthropic API will not accept a sequence of messages where the role of two 
            # sequentian messages is the same.
            #
            # The purpose of this code is to identify such occurences and coalece them such 
            # that the first message in the sequence aggregates the contents of all subsequent
            # messages with the same role.
            look_ahead_index = index + 1; while look_ahead_index < length
              ahead_message = messages[ look_ahead_index ]
              unless ahead_message.nil?
                if ahead_message[ :role ] == message[ :role ]
                  message[ :contents ] = 
                    ( message[ :contents ] || [] ) + 
                    ( ahead_message[ :contents ] || [] )
                  messages[ look_ahead_index ] = nil 
                  look_ahead_index += 1
                else 
                  break
                end
              end
            end

            result_message = { role: message[ :role ] }
            result_message_contents = []
            
            message[ :contents ]&.each do | content |
              cache_control = content[ :'anthropic/cache_control' ]
              case content[ :type ]
              when :text
                result_message_content = { type: 'text', text: content[ :text ] }
                result_message_content[ :cache_control ] = cache_control if cache_control
                result_message_contents << result_message_content
              when :thought
                signature = content[ :'anthropic/signature' ]
                if signature && signature.length > 0 
                  result_message_contents << { 
                    type:                   'thinking', 
                    thinking:               content[ :text ], 
                    signature:              signature 
                  }
                end
              when :cipher_thought
                # nop
              when :binary
                content_type = content[ :content_type ]
                bytes = content[ :bytes ]
                if content_type && bytes
                  if SUPPORTED_CONTENT_TYPES.include?( content_type )
                    result_message_content = {
                      type: content_type == 'application/pdf' ? 'document' : 'image',
                      source: {
                        type: 'base64',
                        media_type: content_type,
                        data: Base64.strict_encode64( bytes )
                      }
                    }
                    result_message_content[ :cache_control ] = cache_control if cache_control            
                    result_message_contents << result_message_content
                  else
                    raise UnsupportedContentError.new( 
                      :anthropic, 
                      'only support content of type image/*' 
                    ) 
                  end
                else 
                  raise UnsupportedContentError.new(
                    :anthropic, 
                    'requires file content to include content type and (packed) bytes'  
                  )
                end
              when :file 
                content_type = content[ :content_type ]
                uri = content[ :uri ]
                if content_type && uri  
                  if SUPPORTED_CONTENT_TYPES.include?( content_type )
                    result_message_content = {
                      type: content_type == 'application/pdf' ? 'document' : 'image',
                      source: {
                        type: 'url',
                        url: uri 
                      }
                    }
                    result_message_content[ :cache_control ] = cache_control if cache_control            
                    result_message_contents << result_message_content
                  else 
                    raise UnsupportedContentError.new( 
                      :anthropic, 
                      "only supports content of type #{SUPPORTED_CONTENT_TYPES.join( ', ' )}" 
                    ) 
                  end 
                else 
                  raise UnsupportedContentError.new(
                    :anthropic, 
                    'requires file content to include content type and uri'  
                  )
                end 
              when :tool_call 
                tool_parameters = content[ :tool_parameters ]
                tool_parameters = {} \
                  if tool_parameters.nil? || 
                     ( tool_parameters.is_a?( String ) && tool_parameters.empty? )
                result_message_content = {
                  type: 'tool_use',
                  id: content[ :tool_call_id ],
                  name: content[ :tool_name ],
                  input: tool_parameters
                }
                result_message_content[ :cache_control ] = cache_control if cache_control            
                result_message_contents << result_message_content
              when :tool_result 
                result_message_content = {
                  type: 'tool_result',
                  tool_use_id: content[ :tool_call_id ],
                  content: content[ :tool_result ]&.to_s
                }
                result_message_content[ :cache_control ] = cache_control if cache_control            
                result_message_contents << result_message_content
              when :web_search_call, :web_reference
                # nop
              else
                raise UnsupportedContentError.new( 
                  :anthropic, 
                  "does not support content of type '#{content[ :type ]}'." 
                ) 
              end
            end
  
            result_message[ :content ] = result_message_contents
            result[ :messages ] << result_message
          
          end
        
          index += 1 

        end
        
        tools_attributes = chat_request_tools_attributes( 
          ( result[ :tools ] || [] ).concat( tools ) 
        )
        result[ :tools ] = tools_attributes if tools_attributes && tools_attributes.length > 0

        JSON.generate( result )
      end 

      def chat_request_tools_attributes( tools ) 
        properties_array_to_object = lambda do | properties |
          return nil unless properties&.any? 
          object = {}
          required = []
          properties.each do | property | 
            property = property.dup 
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
          tool_attributes = { 
            name: tool[ :name ],
            description: tool[ :description ],
            input_schema: { type: 'object' }
          }
      
          if tool[ :properties ]&.any? 
            properties_object, properties_required = 
              properties_array_to_object.call( tool[ :properties ] ) 
            input_schema = {
              type: 'object',
              properties: properties_object 
            }
            input_schema[ :required ] = properties_required if properties_required.any?
            tool_attributes[ :input_schema ] = input_schema
          end
          tool_attributes 
        end
      end

    private 

      def to_anthropic_system_message( system_message )
        return nil if system_message.nil?
        
        # note: the current version of the anthropic api simply takes a string as the 
        #       system message but the beta version requires an array of objects akin
        #       to message contents.
        result = ''
        system_message[ :contents ].each do | content |
          result += content[ :text ] if content[ :type ] == :text 
        end

        result.empty? ? nil : result 
      end 

    end
  end
end
