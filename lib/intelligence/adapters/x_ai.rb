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
