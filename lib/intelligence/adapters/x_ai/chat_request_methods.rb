module Intelligence
  module XAi
    module ChatRequestMethods

      def chat_request_body( conversation, options = nil )
        tools = options.delete( :tools ) || []
        web_search_parameters = options.delete( :search_parameters ) || {}

        options = merge_options( @options, build_options( options ) )
        
        result = options[ :chat_options ]
        result[ :messages ] = []

        system_message = chat_request_system_message_attributes( conversation[ :system_message ] )
        result[ :messages ] << system_message if system_message

        conversation[ :messages ]&.each do | message |
          return nil unless message[ :contents ]&.any?

          result_message = { role: message[ :role ] }
          result_message_content = []

          message_contents = message[ :contents ]

          # tool calls in the open ai api are not content
          tool_calls, message_contents = message_contents.partition do | content | 
            content[ :type ] == :tool_call 
          end 

          # tool results in the open ai api are not content
          tool_results, message_contents = message_contents.partition do | content |
            content[ :type ] == :tool_result 
          end 

          # many vendor api's, especially when hosting text only models, will only accept a single 
          # text content item; if the content is only text this will coalece multiple text content 
          # items into a single content item
          unless message_contents.any? { | c | c[ :type ] != :text }
            result_message_content = message_contents.map { | c | c[ :text ] || '' }.join( "\n" )
          else  
            message_contents&.each do | content |
              result_message_content << chat_request_message_content_attributes( content )
            end
          end

          if tool_calls.any?
            result_message[ :tool_calls ] = tool_calls.map { | tool_call |
              {
                id: tool_call[ :tool_call_id ],
                type: 'function',
                function: {
                  name: tool_call[ :tool_name ],
                  arguments: JSON.generate( tool_call[ :tool_parameters ] || {} )
                }
              }
            }
          end 

          result_message[ :content ] = result_message_content 
          unless result_message_content.empty? && tool_calls.empty? 
           result[ :messages ] << result_message 
          end 

          if tool_results.any? 
            result[ :messages ].concat( tool_results.map { | tool_result |
              {
                role: :tool, 
                tool_call_id: tool_result[ :tool_call_id ],
                content: tool_result[ :tool_result ]
              }
            } )
          end 
        end 

        tools_attributes = chat_request_tools_attributes( 
          ( result[ :tools ] || [] ).concat( tools ) 
        )
        result[ :tools ] = tools_attributes if tools_attributes && tools_attributes.length > 0

        ability_attributes = result[ :abilities ]
        if ability_attributes && ability_attributes[ :search_parameters ]
          result[ :search_parameters ] = 
            ability_attributes[ :search_parameters ].merge( web_search_parameters )
        end
        
        JSON.generate( result )
      end

    end

  end
end
