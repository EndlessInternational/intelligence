require_relative 'generic/adapter'

module Intelligence
  module Hyperbolic

    class Adapter < Generic::Adapter

      chat_request_uri "https://api.hyperbolic.xyz/v1/chat/completions"
      
      schema do 
        key                 String 
        chat_options do 
          model             String
          temperature       Float
          top_p             Float
          n                 Integer
          max_tokens        Integer
          stop              String, array: true
          stream            [ TrueClass, FalseClass ]
          frequency_penalty Float
          presence_penalty  Float
          user              String
        end
      end

      def chat_result_error_attributes( response )

        error_type, error_description = translate_error_response_status( response.status )
        result = {
          error_type: error_type.to_s,
          error_description: error_description
        }
        parsed_body = JSON.parse( response.body, symbolize_names: true ) rescue nil 
        if parsed_body && parsed_body.respond_to?( :include? )
          if parsed_body.include?( :error )
            result = {
              error_type: error_type.to_s,
              error: parsed_body[ :error ][ :code ] || error_type.to_s,
              error_description: parsed_body[ :error ][ :message ] || error_description
            }
          elsif parsed_body.include?( :detail )
            result[ :error_description ] = parsed_body[ :detail ]
          elsif parsed_body[ :object ] == 'error'
            result[ :error_description ] = parsed_body[ :message ]
          end
        end

        result

      end

    end

  end
end
