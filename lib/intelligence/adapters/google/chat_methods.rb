require 'uri'

module Intelligence
  module Google
    module ChatMethods

      GENERATIVE_LANGUAGE_URI = "https://generativelanguage.googleapis.com/v1beta/models/"

      def chat_request_uri( options )
        options = options ? self.class.configure( options ) : {}
        options = @options.merge( options )

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
        options = options ? self.class.configure( options ) : {}
        options = @options.merge( options )

        gc = options[ :generationConfig ]
        # discard properties not part of the google generationConfig schema
        gc.delete( :model )
        gc.delete( :stream )

        result = {}
        result[ :generationConfig ] = gc

        # construct the system prompt in the form of the google schema
        system_instructions = translate_system_message( conversation[ :system_message ] )
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
                unless MIME::Types[ content_type ].empty?
                  # TODO: verify the specific google supported MIME types
                  result_message_parts << {
                    inline_data: {
                      mime_type: content_type,
                      data: Base64.strict_encode64( bytes )
                    }
                  }
                else
                  raise UnsupportedContentError.new( 
                    :google, 
                    'only support recognized mime types' 
                  ) 
                end
              else 
                raise UnsupportedContentError.new(
                  :google, 
                  'requires binary content to include content type and ( packed ) bytes'  
                )
              end
            end 
          end

          result_message[ :parts ] = result_message_parts
          result[ :contents ] << result_message

        end

        JSON.generate( result )

      end 

      def chat_result_attributes( response )

        return nil unless response.success?

        response_json = JSON.parse( response.body, symbolize_names: true ) rescue nil
        return nil \
          if response_json.nil? || response_json[ :candidates ].nil?
        
        result = {}
        result[ :choices ] = []

        response_json[ :candidates ]&.each do | response_choice |

          end_reason = translate_finish_reason( response_choice[ :finishReason ] )
          
          role = nil 
          contents = []

          response_content = response_choice[ :content ]
          if response_content
            role = ( response_content[ :role ] == 'model' ) ? 'assistant' : 'user'

            contents = []
            response_content[ :parts ]&.each do | response_content_part |
              if response_content_part.key?( :text )              
                contents.push( {
                  type: 'text', text: response_content_part[ :text ]
                } )
              end
            end
          end

          result_message = nil 
          if role
            result_message = { role: role }
            result_message[ :contents ] = contents
          end

          result[ :choices ].push( { end_reason: end_reason, message: result_message } )
        
        end

        metrics_json = response_json[ :usageMetadata ]
        unless metrics_json.nil?

          metrics = {}
          metrics[ :input_tokens ] = metrics_json[ :promptTokenCount ] 
          metrics[ :output_tokens ] = metrics_json[ :candidatesTokenCount ]
          metrics = metrics.compact

          result[ :metrics ] = metrics unless metrics.empty?

        end

        result
      
      end

      def chat_result_error_attributes( response )

        error_type, error_description = translate_error_response_status( response.status )
        result = { error_type: error_type.to_s, error_description: error_description }

        response_body = JSON.parse( response.body, symbolize_names: true ) rescue nil 
        if response_body && response_body[ :error ]
          error_details_reason = response_body[ :error ][ :details ]&.first&.[]( :reason )
          # a special case for authentication 
          error_type = :authentication_error if error_details_reason == 'API_KEY_INVALID'
          result = {
            error_type: error_type.to_s,
            error: error_details_reason || response_body[ :error ][ :status ] || error_type,
            error_description: response_body[ :error ][ :message ]
          }
        end
        result

      end

      def stream_result_chunk_attributes( context, chunk )
      #---------------------------------------------------

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

          data = JSON.parse( line, symbolize_names: true )
          if data.is_a?( Hash )
            
            data[ :candidates ]&.each do | data_candidate |

              data_candidate_index = data_candidate[ :index ] || 0
              data_candidate_content = data_candidate[ :content ]
              data_candidate_finish_reason = data_candidate[ :finishReason ]
              choices.fill( { message: { role: 'assistant' } }, choices.size, data_candidate_index + 1 ) \
                if choices.size <= data_candidate_index 
              contents = choices[ data_candidate_index ][ :message ][ :contents ] || []
              last_content = contents&.last 
              
              if data_candidate_content&.include?( :parts ) 
                data_candidate_content_parts = data_candidate_content[ :parts ]
                data_candidate_content_parts&.each do | data_candidate_content_part |
                  if data_candidate_content_part.key?( :text )
                    if last_content.nil? || last_content[ :type ] != :text
                      contents.push( { type: :text, text: data_candidate_content_part[ :text ] } )
                    else 
                      last_content[ :text ] = 
                        ( last_content[ :text ] || '' ) + data_candidate_content_part[ :text ]
                    end
                  end
                end
              end
              choices[ data_candidate_index ][ :message ][ :contents ] = contents
              choices[ data_candidate_index ][ :end_reason ] = 
                translate_finish_reason( data_candidate_finish_reason )
            end
  
            if usage = data[ :usageMetadata ]
              metrics[ :input_tokens ] = usage[ :promptTokenCount ]
              metrics[ :output_tokens ] = usage[ :candidatesTokenCount ]
            end 

          end

        end

        context[ :buffer ] = buffer 
        context[ :metrics ] = metrics
        context[ :choices ] = choices

        [ context, choices.empty? ? nil : { choices: choices.dup } ]

      end

      def stream_result_attributes( context )
      #--------------------------------------

        choices = context[ :choices ]
        metrics = context[ :metrics ]

        choices = choices.map do | choice |
          { end_reason: choice[ :end_reason ] }
        end

        { choices: choices, metrics: context[ :metrics ] }

      end

      alias_method :stream_result_error_attributes, :chat_result_error_attributes

      private; def translate_system_message( system_message )
      # -----------------------------------------------------

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

      private; def translate_finish_reason( finish_reason )
      # ---------------------------------------------------
        case finish_reason
          when 'STOP'
            :ended
          when 'MAX_TOKENS'
            :token_limit_exceeded
          when 'SAFETY', 'RECITATION', 'BLOCKLIST', 'PROHIBITED_CONTENT', 'SPII'
            :filtered
          else
            nil
        end
      end
    
      private; def translate_error_response_status( status )
        case status
          when 400
            [ :invalid_request_error, 
              "There was an issue with the format or content of your request." ]
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
