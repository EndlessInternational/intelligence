module Intelligence
  module Anthropic
    module ChatMethods

      CHAT_REQUEST_URI = "https://api.anthropic.com/v1/messages"

      def chat_request_uri( options )
        CHAT_REQUEST_URI
      end

      def chat_request_headers( options = nil )
        options = options ? self.class.configure( options ) : {}
        options = @options.merge( options )
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
        options = options ? self.class.configure( options ) : {}
        options = @options.merge( options )
        result = options[ :chat_options ]&.compact || {}

        system_message = translate_system_message( conversation[ :system_message ] )
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
                  raise InvalidContentError.new( :anthropic ) 
                end
              end 
            end
            
            result_message[ :content ] = result_message_content
            result[ :messages ] << result_message
          
          end
        
          index += 1
        
        end

        JSON.generate( result )
      end 

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
            if content[ :type ] == 'text'
              result_content.push( { type: 'text', text: content[ :text ] } )
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
        contents = context[ :contents ] || []    
        end_reason = context[ :end_reason ]
        end_sequence = context[ :end_sequence ]
        metrics = context[ :metrics ] || {
          input_tokens: 0,
          output_tokens:  0
        }

        contents.each do | content |
          case content[ :type ] 
            when :text 
              content[ :text ] = ''
            when :tool_call 
              content[ :tool_parameters ] = ''
            else 
              content.clear 
          end
        end

        buffer += chunk
        while ( eol_index = buffer.index( "\n" ) )
          
          line = buffer.slice!( 0..eol_index )
          line = line.strip 
          next if line.empty? || !line.start_with?( 'data:' )

          line = line[ 6..-1 ]
          data = JSON.parse( line )
          
          case data[ 'type' ]
            when 'message_start'
              metrics[ :input_tokens ] += data[ 'message' ]&.[]( 'usage' )&.[]( 'input_tokens' ) || 0
              metrics[ :output_tokens ] += data[ 'message' ]&.[]( 'usage' )&.[]( 'output_tokens' ) || 0
            when 'content_block_start'
              index = data[ 'index' ]
              contents.fill( {}, contents.size, index + 1 ) if contents.size <= index
              if content_block = data[ 'content_block' ]
                if content_block[ 'type' ] == 'text'
                  contents[ index ] = {
                    type: :text,
                    text: content_block[ 'text' ] || '' 
                  }
                elsif content_block[ 'type' ] == 'tool_use'
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
              contents.fill( {}, contents.size, index + 1 ) if contents.size <= index
              if delta = data[ 'delta' ]
                if delta[ 'type' ] == 'text_delta'
                  contents[ index ][ :type ] = :text 
                  contents[ index ][ :text ] = ( contents[ index ][ :text ] || '' ) + delta[ 'text' ]
                elsif delta[ 'type' ] == 'input_json_delta'
                  contents[ index ][ :type ] = :tool_call 
                  contents[ index ][ :tool_parameters ] = 
                    ( contents[ index ][ :tool_parameters ] || '' ) + delta[ 'input_json_delta' ]                
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

        context = {
          buffer: buffer,
          contents: contents,
          end_reason: end_reason,
          end_sequence: end_sequence,
          metrics: metrics
        }
        choices = [ {
            end_reason: translate_end_result( end_reason ),
            end_sequence: end_sequence,
            message: {
              contents: contents.dup
            }
          }
        ]

        [ context, ( choices.empty? ? nil : { choices: choices } ) ]
      end

      def stream_result_attributes( context )
        {
          choices: [ { 
            end_reason: translate_end_result( context[ :end_reason ] ),
            end_sequence: context[ :end_sequence ], 
          } ],
          metrics: context[ :metrics ]
        }
      end

      alias_method :stream_result_error_attributes, :chat_result_error_attributes 

    private 

      def translate_system_message( system_message )

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
