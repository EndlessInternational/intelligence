require_relative 'generic/adapter'

module Intelligence
  module XAi 

    class Adapter < Generic::Adapter

      DEFAULT_BASE_URI            = "https://api.x.ai/v1"

      schema do 
      
        base_uri                  String, default: DEFAULT_BASE_URI
        key                       String 

        chat_options do 
          model                   String
          frequency_penalty       Float, in: -2..2
          logit_bias              Hash 
          logprobs                [ TrueClass, FalseClass ]
          max_tokens              Integer 
          n                       Integer
          presence_penalty        Float, in: -2..2
          response_format 
          seed                    Integer 
          stop                    String, array: true
          stream                  [ TrueClass, FalseClass ]
          stream_options 
          temperature             Float, in: 0..2

          tool                    array: true, as: :tools, &Tool.schema 
          tool_choice 

          top_logprobs            Integer, in: 0..20
          top_p                   Float 
          
          user                    String 
        
        end
      end

      def chat_result_attributes( response )
        return nil unless response.success?
        response_json = JSON.parse( response.body, symbolize_names: true ) rescue nil
        return nil if response_json.nil? || response_json[ :choices ].nil?

        result = {}
        result[ :choices ] = []

        ( response_json[ :choices ] || [] ).each do | json_choice |
          end_reason = to_end_reason( json_choice[ :finish_reason ] )
          if ( json_message = json_choice[ :message ] )
            result_message = { role: json_message[ :role ] }
            if json_message[ :content ] 
              result_message[ :contents ] = [ { type: :text, text: json_message[ :content ] } ]
            end
            if json_message[ :tool_calls ] && !json_message[ :tool_calls ].empty?
              result_message[ :contents ] ||= []
              end_reason = :tool_called if end_reason == :ended
              json_message[ :tool_calls ].each do | json_message_tool_call |
                result_message_tool_call_parameters = 
                  JSON.parse( json_message_tool_call[ :function ][ :arguments ], symbolize_names: true ) \
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
