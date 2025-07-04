module Intelligence
  module OpenAi
    module ChatResponseMethods

      def chat_result_attributes( response )
        return nil unless response.success?
        response_json = JSON.parse( response.body, symbolize_names: true ) rescue nil
        return nil if response_json.nil? 
        
        result = { id: response_json[ :id ], user: response_json[ :user ] }
        result[ :choices ] = []
        end_reason =  translate_end_result( response_json )

        json_output = response_json[ :output ]
        result_message = { role: 'assistant', contents: [] }
        json_output&.each do | json_payload |
          case json_payload[ :type ]
          when 'reasoning'
            json_payload[ :summary ]&.each do | json_content |
              case json_content[ :type ]
              when 'summary_text'
                result_message[ :contents ] << { type: :thought, text: json_content[ :text ] }
              end
            end
          when 'message'
            json_payload[ :content ]&.each do | json_content |
              case json_content[ :type ]
              when 'output_text'
                result_message[ :contents ] << { type: :text, text: json_content[ :text ] }
                json_content[ :annotations ]&.each do | json_annotation |
                  result_message[ :contents ] << { 
                    type: :web_reference, 
                    uri: json_annotation[ :url ],
                    title: json_annotation[ :title ]
                  }
                end
              end
            end
          when 'function_call'
            end_reason = :tool_called if end_reason == :ended
            result_message_tool_call_parameters = nil
            if json_payload[ :arguments ]
              result_message_tool_call_parameters = json_payload[ :arguments ]  
              begin 
                result_message_tool_call_parameters = 
                  JSON.parse( json_payload[ :arguments ], symbolize_names: true ) 
              rescue 
              end
            end
            result_message[ :contents ] << {
              type: :tool_call, 
              tool_call_id: json_payload[ :call_id ],
              tool_name: json_payload[ :name ],
              tool_parameters: result_message_tool_call_parameters
            }
          when 'web_search_call'
            web_search_action = json_payload[ :action ] || {}
            result_message[ :contents ] << { 
              type: :web_search_call, 
              query: web_search_action[ :query ],
              status: :complete
            }
          end
        end 
        result[ :choices ].push( { end_reason: end_reason, message: result_message } )

        metrics_json = response_json[ :usage ]
        unless metrics_json.nil?

          metrics = {}
          metrics[ :input_tokens ] = metrics_json[ :input_tokens ] 
          metrics[ :output_tokens ] = metrics_json[ :output_tokens ]
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
            id: parsed_body[ :id ],
            user: parsed_body[ :user ],
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
        choices = context[ :choices ] || Array.new( 1 , { message: { contents: [] } } )
        # purge content items of their content as we only emit content deltas ( while the emited 
        # structure is always consistent )
        choices.each do | choice |
          choice[ :message ][ :contents ] = choice[ :message ][ :contents ]&.map do | content |
            { item_id: content[ :item_id ], type: content[ :type ] }
          end
        end

        # the open ai responses api only ever return only 1 intelligence choice with 1 message
        choice = choices.last
        message = choice[ :message ]
        contents = message[ :contents ] || []
        annotations = []

        buffer += chunk
        while ( eol_index = buffer.index( "\n" ) )
          line = buffer.slice!( 0..eol_index )        
          line = line.strip 
          next if line.empty? || !line.start_with?( 'data:' )
          line = line[ 6..-1 ]

          next if line.end_with?( '[DONE]' )
          data = JSON.parse( line, symbolize_names: true ) rescue nil
          # puts line
          # empty content is suppressed
          content = last_content = contents.last
          content_present = false

          if data.is_a?( Hash )
            case data[ :type ]
            when 'response.output_item.added'
              response_item = data[ :item ]
              case response_item[ :type ]
              # tool_call 
              when 'function_call'
                content = {
                  item_id: response_item[ :id ],
                  type: 'tool_call',
                  tool_name: response_item[ :name ],
                  tool_call_id: response_item[ :call_id ],
                  tool_parameters: response_item[ :arguments ]
                }
                content_present = true
              # web_search_call 
              when 'web_search_call'
                content = { item_id: response_item[ :id ], type: 'web_search_call', status: :searching }
                content_present = true
              end
            when 'response.function_call_arguments.delta'
              raise 'A functiona call argument delta was received but there is not tool content.' \
                unless content and content[ :type ] == 'tool_call'
              raise 'A functiona call argument delta was received but item id does not match.' \
                unless content[ :item_id ] = data[ :item_id ]
              ( content[ :tool_parameters ] ||= '' ) << data[ :delta ] 
            # thought 
            when 'response.reasoning_summary_part.added'
              response_item_id = "#{data[ :item_id ]}:#{data[ :summary_index ]}"
              response_part_json = data[ :part ]
              raise 'A reasoning content item was created but it is not `summary_text`.' \
                if response_part_json[ :type ] != 'summary_text'
              response_text = response_part_json[ :text ]
              if content.nil? || content[ :item_id ] != response_item_id
                content = { 
                  item_id: response_item_id, 
                  type: 'thought', 
                  text: response_text || '' 
                }
                content_present = response_text && response_text.length > 0
              end 
            when 'response.reasoning_summary_text.delta'
              response_item_id = "#{data[ :item_id ]}:#{data[ :summary_index ]}"
              response_text = data[ :delta ]
              if content.nil? || content[ :item_id ] != response_item_id
                content = { 
                  item_id: response_item_id, 
                  type: 'thought', 
                  text: response_text || '' 
                }
                content_present = response_text && response_text.length > 0
              else 
                content_present = ( ( content[ :text ] ||= '' ) << response_text ).size.positive?
              end
            # text
            when 'response.content_part.added'
              response_item_id = "#{data[ :item_id ]}:#{data[ :content_index ]}"
              response_part_json = data[ :part ]
              raise 'A content item was created but it is not `output_text`.' \
                if response_part_json[ :type ] != 'output_text'
              response_text = response_part_json[ :text ]
              if content.nil? || content[ :item_id ] != response_item_id
                content = { 
                  item_id: response_item_id, 
                  type: 'text', 
                  text: response_text || '' 
                }
                content_present = response_text && response_text.length > 0
              end 
            when 'response.output_text.delta'
              response_item_id = "#{data[ :item_id ]}:#{data[ :content_index ]}"
              response_text = data[ :delta ]
              if content.nil? || content[ :item_id ] != response_item_id
                content = { 
                  item_id: response_item_id, 
                  type: 'text', 
                  text: response_text || '' 
                }
                content_present = response_text && response_text.length > 0
              else 
                content_present = ( ( content[ :text ] ||= '' ) << response_text ).size.positive?
              end
            when 'response.output_item.done'
              response_item = data[ :item ]
              case response_item[ :type ]
              # text 
              when 'message'
                if response_item_contents = response_item[ :content ]
                  response_item_contents.each do | response_item_content |
                    if response_item_annotations = response_item_content[ :annotations ]
                      response_item_annotations.each do | response_item_annotation |
                        if response_item_annotation[ :type ] == 'url_citation'
                          annotations << {
                            type: :web_reference,
                            title: response_item_annotation[ :title ],
                            uri: response_item_annotation[ :url ]
                          }
                        end
                      end
                    end
                  end
                end
              # web search complete
              when 'web_search_call'
                raise 'A web search call completed but there is web search call content.' \
                  unless content and content[ :type ] == 'web_search_call'
                raise 'A web search call completed but item id does not match.' \
                  unless content[ :item_id ] = response_item[ :id ]
                web_search_call_action = response_item[ :action ] || {}
                content[ :query  ] = web_search_call_action[ :query ]
                content[ :status ] = :complete
              end
            when 'response.completed', 'response.incomplete'
              response_json = data[ :response ]
              end_reason = translate_end_result( response_json )
              choice[ :end_reason ] = end_reason
              choice[ :end_reason ] = :tool_called \
                if end_reason == :ended && last_content[ :type ] == 'tool_call'

              metrics_json = response_json[ :usage ]
              unless metrics_json.nil?

                metrics = {}
                metrics[ :input_tokens ] = metrics_json[ :input_tokens ] 
                metrics[ :output_tokens ] = metrics_json[ :output_tokens ]
                metrics = metrics.compact

              end

            end

            if ( !last_content || last_content[ :item_id ] != content[ :item_id ] ) && content_present
              contents.push( content )
            end
            annotations.each { | annotation | contents.push( annotation ) }
            annotations = []

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

      def translate_end_result( response_json )
        return :ended if response_json[ :status ] == 'completed'
        case response_json[ :status ]
        when 'incomplete'
          case ( response_json[ :incomplete_details ][ :reason ] rescue nil )
          when 'max_output_tokens'
            :token_limit_exceeded
          end 
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
