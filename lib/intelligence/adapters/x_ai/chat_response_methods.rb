module Intelligence
  module XAi
    module ChatResponseMethods

      def chat_result_attributes( response )
        return nil unless response.success?
        response_json = JSON.parse( response.body, symbolize_names: true ) rescue nil
        return nil if response_json.nil? || response_json[ :choices ].nil?

        # these are just randomly sitting on the root :eyeroll
        citations = response_json[ :citations ]

        result = {}
        result[ :choices ] = []
        ( response_json[ :choices ] || [] ).each do | json_choice |
          end_reason = to_end_reason( json_choice[ :finish_reason ] )
          if ( json_message = json_choice[ :message ] )
            result_message = { role: json_message[ :role ], contents: [] }

            if json_message[ :reasoning_content ]&.length&.positive?
              result_message[ :contents ] << 
                { type: :thought, text: json_message[ :reasoning_content ] }
            end

            if json_message[ :content ] 
              result_message[ :contents ] << 
                { type: :text, text: json_message[ :content ] }
            end

            citations&.each do | citation |
              result_message[ :contents ] << 
                { type: :web_reference, uri: citation }
            end

            if json_message[ :tool_calls ] && !json_message[ :tool_calls ].empty?
              result_message[ :contents ] ||= []
              end_reason = :tool_called if end_reason == :ended
              json_message[ :tool_calls ].each do | json_message_tool_call |
                result_message_tool_call_parameters = 
                  JSON.parse( json_message_tool_call[ :function ][ :arguments ], 
                              symbolize_names: true ) \
                    rescue json_message_tool_call[ :function ][ :arguments ]
                result_message[ :contents ] << {
                  type: :tool_call, 
                  tool_call_id: json_message_tool_call[ :id ],
                  tool_name: json_message_tool_call[ :function ][ :name ],
                  tool_parameters: result_message_tool_call_parameters
                }
              end 
            end

          end
          result[ :choices ].push( { end_reason: end_reason, message: result_message } )
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

      def stream_result_chunk_attributes( context, chunk )
        
        context ||= {}
        buffer = context[ :buffer ] || ''
        metrics = context[ :metrics ] || {
          input_tokens: 0,
          output_tokens:  0
        }
        choices = context[ :choices ] || Array.new( 1 , { message: {} } )
        choices_delta = prune_choices( choices )

        buffer += chunk
        while ( eol_index = buffer.index( "\n" ) )
          line = buffer.slice!( 0..eol_index )        
          line = line.strip 
          next if line.empty? || !line.start_with?( 'data:' )
          line = line[ 6..-1 ]
          next if line.end_with?( '[DONE]' )

          data = JSON.parse( line ) rescue nil

          if data.is_a?( Hash )
            data[ 'choices' ]&.each do | data_choice |

              data_choice_index = data_choice[ 'index' ]
              data_choice_delta = data_choice[ 'delta' ]

              finish_reason = data_choice[ 'finish_reason' ]
              end_reason = to_end_reason( finish_reason ) if finish_reason
              
              choices_delta.fill( { message: {} }, choices_delta.size, data_choice_index + 1 ) \
                if choices_delta.size <= data_choice_index 
              contents = choices_delta[ data_choice_index ][ :message ][ :contents ] || []

              if data_choice_reasoning_content = data_choice_delta[ 'reasoning_content' ]          
                thought_content = contents.last&.[]( :type ) == :thought ? contents.last : nil 
                if thought_content.nil?  
                  contents.push( { type: :thought, text: data_choice_reasoning_content } )
                else
                    thought_content[ :text ] = 
                      ( thought_content[ :text ] || '' ) + data_choice_reasoning_content
                end
              end 

              if data_choice_content = data_choice_delta[ 'content' ]          
                text_content = contents.last&.[]( :type ) == :text ? contents.last : nil 
                if text_content.nil?  
                  contents.push( text_content = { type: :text, text: data_choice_content } )
                else
                  text_content[ :text ] = ( text_content[ :text ] || '' ) + data_choice_content
                end
              end 

              if data_choice_tool_calls = data_choice_delta[ 'tool_calls' ]
                data_choice_tool_calls.each_with_index do | data_choice_tool_call, data_choice_tool_call_index |
                  if data_choice_tool_call_function = data_choice_tool_call[ 'function' ]
                    data_choice_tool_index = data_choice_tool_call[ 'index' ] || data_choice_tool_call_index
                    data_choice_tool_id = data_choice_tool_call[ 'id' ]
                    data_choice_tool_name = data_choice_tool_call_function[ 'name' ]
                    data_choice_tool_parameters = data_choice_tool_call_function[ 'arguments' ]
                    
                    # if the data_choice_tool_id is present this indicates a new tool call.
                    if data_choice_tool_id
                      contents.push( { 
                        type: :tool_call, 
                        tool_call_id: data_choice_tool_id,
                        tool_name: data_choice_tool_name,
                        tool_parameters: data_choice_tool_parameters
                      } )
                    # otherwise the tool is being aggregated  
                    else 
                      tool_call_content_index = contents.rindex do | content | 
                        content[ :type ] == :tool_call 
                      end     
                      tool_call = contents[ tool_call_content_index ]
                      if data_choice_tool_parameters
                        tool_call[ :tool_parameters ] = 
                          ( tool_call[ :tool_parameters ] || '' ) + data_choice_tool_parameters
                      end
                    end 
                  end 
                end 
              end

              # the citations are awkwardly placed on the root of the response payload but their 
              # actually specific to the choice/message; the grok api only ever returns one choice
              # and one messages per choice though so :shrug
              data[ 'citations' ]&.each do | citation |
                contents << { type: :web_reference, uri: citation }
              end

              choices_delta[ data_choice_index ][ :message ][ :contents ] = contents
              choices_delta[ data_choice_index ][ :end_reason ] ||= end_reason
            end
  
            if usage = data[ 'usage' ]
              # note: A number of providers will resend the input tokens as part of their usage 
              #       payload.
              metrics[ :input_tokens ] = usage[ 'prompt_tokens' ] \
                if usage.include?( 'prompt_tokens' )
              metrics[ :output_tokens ] += usage[ 'completion_tokens' ] \
                if usage.include?( 'completion_tokens' )
            end 

          end

        end

        context[ :buffer ] = buffer 
        context[ :metrics ] = metrics
        context[ :choices ] = merge_choices!( choices, choices_delta )

        [ context, choices_delta.empty? ? nil : { choices: choices_delta } ]

      end

      def chat_result_error_attributes( response )
        error_type, error_description = to_error_response( response.status )
        error = error_type 

        parsed_body = JSON.parse( response.body, symbolize_names: true ) rescue nil 
        if parsed_body && parsed_body.respond_to?( :[] )
          error = parsed_body[ :code ] || error_type 
          error_description = parsed_body[ :error ] || error_description 
        end 

        { error_type: error_type.to_s, error: error.to_s, error_description: error_description }
      end

      alias_method :stream_result_error_attributes, :chat_result_error_attributes
    
    end
  end
end
