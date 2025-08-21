module Intelligence
  module Anthropic
    module ChatResponseMethods

      def chat_result_attributes( response )
        return nil unless response.success?

        response_json = JSON.parse( response.body, symbolize_names: true ) rescue nil
        return nil if response_json.nil? 

        result = {}
        
        result_choice = { 
          end_reason: translate_end_result( response_json[ :stop_reason ] ),
          end_sequence: response_json[ :stop_sequence ], 
        }

        if response_json[ :content ] && 
           response_json[ :content ].is_a?( Array ) &&
           !response_json[ :content ].empty?

          result_content = []
          response_json[ :content ].each do | content |
            case content[ :type ]
            when 'text'
              result_content.push( { type: 'text', text: content[ :text ] } )
            when 'thinking'
              result_content.push( { 
                type: 'thought', 
                text: content[ :thinking ], 
                ciphertext: content[ :signature ] 
              } )
            when 'tool_use'
              result_content.push( { 
                type: :tool_call, 
                tool_call_id: content[ :id ],
                tool_name: content[ :name ],
                tool_parameters: content[ :input ]
              } )
            end
          end

          unless result_content.empty?
            result_choice[ :message ] = {
              role: response_json[ :role ] || 'assistant',
              contents: result_content
            }
          end

        end

        result[ :choices ] = [ result_choice ]

        metrics_json = response_json[ :usage ]
        unless metrics_json.nil?

          result_metrics = {}
          result_metrics[ :input_tokens ] = metrics_json[ :input_tokens ] 
          result_metrics[ :output_tokens ] = metrics_json[ :output_tokens ]
          result_metrics = result_metrics.compact

          result[ :metrics ] = result_metrics unless result_metrics.empty?

        end

        result 
      end

      def chat_result_error_attributes( response )
        error_type, error_description = translate_response_status( response.status )
        parsed_body = JSON.parse( response.body, symbolize_names: true ) rescue nil 
        if parsed_body && parsed_body.respond_to?( :include? ) && parsed_body.include?( :error )
          result = {
            error_type: error_type.to_s,
            error: parsed_body[ :error ][ :type ],
            error_description: parsed_body[ :error ][ :message ] || error_description
          }
        elsif 
          result = {
            error_type: error_type.to_s,
            error_description: error_description
          } 
        end
        result 
      end

      def stream_result_chunk_attributes( context, chunk )
        context ||= {}

        buffer = context[ :buffer ] || ''
        choices = context[ :choices ] || Array.new( 1 , { message: { contents: [] } } )
        metrics = context[ :metrics ] || {
          input_tokens: 0,
          output_tokens:  0
        }

        end_reason = context[ :end_reason ]
        end_sequence = context[ :end_sequence ]
        contents = choices.first[ :message ][ :contents ]

        contents = contents.map do | content |
          { type: content[ :type ] }
        end

        buffer += chunk
        while ( eol_index = buffer.index( "\n" ) )
          
          line = buffer.slice!( 0..eol_index )
          line = line.strip 
          next if line.empty? || !line.start_with?( 'data:' )

          line = line[ 6..-1 ]
          data = JSON.parse( line )
          #puts line 

          case data[ 'type' ]
            when 'message_start'
              metrics[ :input_tokens ] += data[ 'message' ]&.[]( 'usage' )&.[]( 'input_tokens' ) || 0
              metrics[ :output_tokens ] += data[ 'message' ]&.[]( 'usage' )&.[]( 'output_tokens' ) || 0
            when 'content_block_start'
              index = data[ 'index' ]
              if contents.size <= index
                contents.fill( contents.size..index ) { {} } 
              end
              if content_block = data[ 'content_block' ]
                case content_block[ 'type' ]
                when 'text'
                  contents[ index ] = {
                    type: :text,
                    text: content_block[ 'text' ] || '' 
                  }
                when 'thinking'
                  contents[ index ] = {
                    type: :thought,
                    text: content_block[ 'thinking' ] || '' 
                  }
                when 'tool_use'
                  contents[ index ] = {
                    type: :tool_call,
                    tool_name: content_block[ 'name' ],
                    tool_call_id: content_block[ 'id' ],
                    tool_parameters: ''
                  }
                end
              end
            when 'content_block_delta'
              index = data[ 'index' ]
              contents.fill( {}, contents.size..index ) if contents.size <= index
              if delta = data[ 'delta' ]
                case delta[ 'type' ]
                when 'text_delta'
                  contents[ index ][ :type ] = :text 
                  contents[ index ][ :text ] = ( contents[ index ][ :text ] || '' ) + delta[ 'text' ]
                when 'thinking_delta'
                  contents[ index ][ :type ] = :thought 
                  contents[ index ][ :text ] = ( contents[ index ][ :text ] || '' ) + delta[ 'thinking' ]
                when 'signature_delta'
                  if contents[ index ][ :type ] == :thought 
                    contents[ index ][ :ciphertext ] = delta[ 'signature' ]
                  end
                when 'input_json_delta'
                  contents[ index ][ :type ] = :tool_call 
                  contents[ index ][ :tool_parameters ] = 
                    ( contents[ index ][ :tool_parameters ] || '' ) + delta[ 'partial_json' ]                
                end
              end
            when 'message_delta'
              if delta = data[ 'delta' ]
                end_reason = delta[ 'stop_reason' ]
                end_sequence = delta[ 'stop_sequence' ]
              end
              metrics[ :output_tokens ] += data[ 'usage' ]&.[]( 'output_tokens' ) || 0
            when 'message_stop'
              
          end 
        end

        choices_delta = [ {
            end_reason: translate_end_result( end_reason ),
            end_sequence: end_sequence,
            message: { contents: contents }
          }
        ]

        [ 
          {
            buffer: buffer,
            choices: merge_choices!( choices, choices_delta ),
            end_reason: end_reason,
            end_sequence: end_sequence,
            metrics: metrics
          },
          { choices: choices_delta }
        ]
      end

      def stream_result_attributes( context )
        { choices: context[ :choices ], metrics: context[ :metrics ] }
      end

      alias_method :stream_result_error_attributes, :chat_result_error_attributes 

    private 

      def translate_end_result( end_result )
        case end_result
          when 'end_turn'
            :ended
          when 'max_tokens'
            :token_limit_exceeded
          when 'stop_sequence'
            :end_sequence_encountered
          when 'tool_use'
            :tool_called
          else
            # if the result has already been translated, this simply returns it
            end_result
        end
      end

      def translate_response_status( status )
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
          when 429
            [ :rate_limit_error, 
              "Your account has hit a rate limit." ]
          when 500
            [ :api_error, 
              "An unexpected error has occurred internal to Anthropic's systems." ]
          when 529
            [ :overloaded_error, 
              "Anthropic's API is temporarily overloaded." ]
          else
            [ :unknown_error, "
              An unknown error occurred." ]
          end
      end
    
    end
  end
end
