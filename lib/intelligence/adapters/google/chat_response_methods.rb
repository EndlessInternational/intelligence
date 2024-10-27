require 'uri'

module Intelligence
  module Google
    module ChatResponseMethods

       def chat_result_attributes( response )

        return nil unless response.success?

        response_json = JSON.parse( response.body, symbolize_names: true ) rescue nil
        return nil if response_json.nil? || response_json[ :candidates ].nil?
        
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
              elsif function_call = response_content_part[ :functionCall ]                
                contents.push( {
                  type: :tool_call, 
                  tool_name: function_call[ :name ],
                  tool_parameters: function_call[ :args ]
                } )
                # google does not indicate there is tool call in the stop reason so 
                # we will synthesize this end reason
                end_reason = :tool_called if end_reason == :ended
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

        choices = context[ :choices ]
        metrics = context[ :metrics ]

        choices = choices.map do | choice |
          { end_reason: choice[ :end_reason ] }
        end

        { choices: choices, metrics: context[ :metrics ] }

      end

      alias_method :stream_result_error_attributes, :chat_result_error_attributes

    private 
    
      def translate_finish_reason( finish_reason )
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
    
      def translate_error_response_status( status )
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
