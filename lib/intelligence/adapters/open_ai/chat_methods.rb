module Intelligence
  module OpenAi
    module ChatMethods

      CHAT_REQUEST_URI = "https://api.openai.com/v1/chat/completions"

      SUPPORTED_CONTENT_TYPES = [ 'image/jpeg', 'image/png' ]

      def chat_request_uri( options )
        CHAT_REQUEST_URI
      end

      def chat_request_headers( options = {} )
        options = options ? self.class.configure( options ) : {}
        options = @options.merge( options )
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
        options = options ? self.class.configure( options ) : {}
        options = @options.merge( options )
        result = options[ :chat_options ]&.compact || {}
        result[ :messages ] = []

        system_message = translate_system_message( conversation[ :system_message ] )
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
                mime_type = MIME::Types[ content_type ].first
                if mime_type&.media_type == 'image'
                  result_message_content << {
                    type: 'image_url',
                    image_url: {
                      url: "data:#{content_type};base64,#{Base64.strict_encode64( bytes )}".freeze
                    }
                  }
                else
                  raise UnsupportedContentError.new( 
                    :open_ai, 
                    'only supports content of type image/*' 
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
            else 
              raise InvalidContentError.new( :open_ai ) 
            end

          end

          result_message[ :content ] = result_message_content
          result[ :messages ] << result_message

        end

        JSON.generate( result )
      end 

      def chat_result_attributes( response )
        return nil unless response.success?
        
        response_json = JSON.parse( response.body, symbolize_names: true ) rescue nil
        return nil \
          if response_json.nil? || response_json[ :choices ].nil?
        
        result = {}
        result[ :choices ] = []

        ( response_json[ :choices ] || [] ).each do | json_choice |
          json_message = json_choice[ :message ]
          result[ :choices ].push(
            { 
              end_reason: translate_end_result( json_choice[ :finish_reason ] ), 
              message: { 
                role: json_message[ :role ],
                contents: [ { type: 'text', text: json_message[ :content ] } ]
              } 
            }
          )
        end

        metrics_json = response_json[ :usage ]
        unless metrics_json.nil?

          metrics = {}
          metrics[ :input_tokens ] = metrics_json[ :prompt_tokens ] 
          metrics[ :output_tokens ] = metrics_json[ :completion_tokens ]
          metrics = metrics.compact

          result[ :metrics ] = metrics unless metrics.empty?

        end

        result
      end

      def chat_result_error_attributes( response )
        error_type, error_description = translate_error_response_status( response.status )
        result = {
          error_type: error_type.to_s,
          error_description: error_description
        }

        parsed_body = JSON.parse( response.body, symbolize_names: true ) rescue nil 
        if parsed_body && parsed_body.respond_to?( :include? ) && parsed_body.include?( :error )
          result = {
            error_type: error_type.to_s,
            error: parsed_body[ :error ][ :code ] || error_type.to_s,
            error_description: parsed_body[ :error ][ :message ] || error_description
          }
        end
        
        result
      end

      def stream_result_chunk_attributes( context, chunk )
        context ||= {}
        buffer = context[ :buffer ] || ''
        metrics = context[ :metrics ] || {
          input_tokens: 0,
          output_tokens:  0
        }
        choices = context[ :choices ] || Array.new( 1 , { message: {} } )

        choices.each do | choice |
          choice[ :message ][ :contents ] = choice[ :message ][ :contents ]&.map do | content |
            case content[ :type ] 
              when :text 
                content[ :text ] = ''
              when :tool_call 
                content[ :tool_parameters ] = ''
              else 
                content.clear 
            end
            content
          end
        end

        buffer += chunk
        while ( eol_index = buffer.index( "\n" ) )
          
          line = buffer.slice!( 0..eol_index )        
          line = line.strip 
          next if line.empty? || !line.start_with?( 'data:' )
          line = line[ 6..-1 ]

          next if line.end_with?( '[DONE]' )
          data = JSON.parse( line )

          if data.is_a?( Hash )
            
            data[ 'choices' ]&.each do | data_choice |

              data_choice_index = data_choice[ 'index' ]
              data_choice_delta = data_choice[ 'delta' ]
              data_choice_finish_reason = data_choice[ 'finish_reason' ]
              
              choices.fill( { message: {} }, choices.size, data_choice_index + 1 ) \
                if choices.size <= data_choice_index 
              contents = choices[ data_choice_index ][ :message ][ :contents ] || []
              last_content = contents&.last 
              
              if data_choice_delta.include?( 'content' ) 
                data_choice_content = data_choice_delta[ 'content' ] || ''
                if last_content.nil? || last_content[ :type ] == :tool_call
                  contents.push( { type: :text, text: data_choice_content } )
                elsif last_content[ :type ].nil?
                  last_content[ :type ] = :text 
                  last_content[ :text ] = data_choice_content
                elsif last_content[ :type ] == :text 
                  last_content[ :text ] = ( last_content[ :text ] || '' ) + data_choice_content
                end
              elsif data_choice_delta.include?( 'function_call' )
                data_choice_tool_call = data_choice_delta[ 'function_call' ] 
                data_choice_tool_name = data_choice_tool_call[ 'name' ]
                data_choice_tool_parameters = data_choice_tool_call[ 'arguments' ]
                if last_content.nil? || last_content[ :type ] == :text
                  contents.push( { 
                    type: :tool_call, 
                    tool_name: data_choice_tool_name,
                    tool_parameters: data_choice_tool_parameters
                  } )
                elsif last_content[ :type ].nil?
                  last_content[ :type ] = :tool_call 
                  last_content[ :tool_name ] = data_choice_tool_name if data_choice_tool_name.present?
                  last_content[ :tool_parameters ] = tool_parameters
                elsif last_content[ :type ] == :tool_call 
                  last_content[ :tool_parameters ] = 
                    ( last_content[ :tool_parameters ] || '' ) + data_choice_tool_parameters
                end
              end
              choices[ data_choice_index ][ :message ][ :contents ] = contents
              choices[ data_choice_index ][ :end_reason ] = 
                translate_end_result( data_choice_finish_reason )
            end
  
            if usage = data[ 'usage' ]
              metrics[ :input_tokens ] += usage[ 'prompt_tokens' ]
              metrics[ :output_tokens ] += usage[ 'completion_tokens' ]
            end 

          end

        end

        context[ :buffer ] = buffer 
        context[ :metrics ] = metrics
        context[ :choices ] = choices
        
        [ context, choices.empty? ? nil : { choices: choices.dup } ]
      end

      def stream_result_attributes( context )
        choices = context[ :choices ]
        metrics = context[ :metrics ]

        choices = choices.map do | choice |
          { end_reason: choice[ :end_reason ] }
        end

        { choices: choices, metrics: context[ :metrics ] }
      end

      alias_method :stream_result_error_attributes, :chat_result_error_attributes

      private; def translate_system_message( system_message )

        return nil if system_message.nil?

        result = ''
        system_message[ :contents ].each do | content |
          result += content[ :text ] if content[ :type ] == :text 
        end

        result.empty? ? nil : result 

      end 

      private; def translate_end_result( end_result )
        case end_result
          when 'stop'
            :ended
          when 'length'
            :token_limit_exceeded
          when 'function_call'
            :tool_called
          when 'content_filter'
            :filtered
          else
            nil
        end
      end

      def translate_error_response_status( status )
        case status
          when 400
            [ :invalid_request_error, 
              "There was an issue with the format or content of your request." ]
          when 401
            [ :authentication_error, 
              "There's an issue with your API key." ]
          when 403
            [ :permission_error, 
              "Your API key does not have permission to use the specified resource." ]
          when 404
            [ :not_found_error, 
              "The requested resource was not found." ]
          when 413
            [ :request_too_large, 
              "Request exceeds the maximum allowed number of bytes." ]
          when 422
            [ :invalid_request_error, 
              "There was an issue with the format or content of your request." ]
          when 429
            [ :rate_limit_error, 
              "Your account has hit a rate limit." ]
          when 500, 502, 503
            [ :api_error, 
              "An unexpected error has occurred internal to the providers systems." ]
          when 529
            [ :overloaded_error, 
              "The providers server is temporarily overloaded." ]
          else
            [ :unknown_error, "
              An unknown error occurred." ]
          end
      end
    
    end

  end

end
