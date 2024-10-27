module Intelligence
  module Anthropic
    module ChatRequestMethods

      CHAT_REQUEST_URI = "https://api.anthropic.com/v1/messages"

      def chat_request_uri( options )
        CHAT_REQUEST_URI
      end

      def chat_request_headers( options = nil )
        options = @options.merge( build_options( options ) )
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
        options = @options.merge( build_options( options ) )
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
            result_message_content = []
            
            message[ :contents ]&.each do | content |
              case content[ :type ]
              when :text
                result_message_content << { type: 'text', text: content[ :text ] }
              when :binary
                content_type = content[ :content_type ]
                bytes = content[ :bytes ]
                if content_type && bytes
                  mime_type = MIME::Types[ content_type ].first
                  if mime_type&.media_type == 'image'
                    result_message_content << {
                      type: 'image',
                      source: {
                        type: 'base64',
                        media_type: content_type,
                        data: Base64.strict_encode64( bytes )
                      }
                    }
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
              when :tool_call 
                result_message_content << {
                  type: 'tool_use',
                  id: content[ :tool_call_id ],
                  name: content[ :tool_name ],
                  input: content[ :tool_parameters ] || {}
                }
              when :tool_result 
                result_message_content << {
                  type: 'tool_result',
                  tool_use_id: content[ :tool_call_id ],
                  content: content[ :tool_result ]
                }
              else
                raise InvalidContentError.new( :anthropic ) 
              end
            end
            
            result_message[ :content ] = result_message_content
            result[ :messages ] << result_message
          
          end
        
          index += 1 

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
