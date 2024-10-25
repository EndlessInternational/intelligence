require_relative 'legacy/adapter'

module Intelligence
  module SambaNova

    class Adapter < Legacy::Adapter

      chat_request_uri "https://api.sambanova.ai/v1/chat/completions"
      
      schema do 

        # normalized properties for all endpoints
        key                   String
        
        # properties for generative text endpoints
        chat_options do 
        
          # normalized properties for samba nova generative text endpoint
          model               String
          max_tokens          Integer
          temperature         Float
          top_p               Float
          top_k               Float
          stop                String, array: true
          stream              [ TrueClass, FalseClass ]

          # samba nova properties for samba nova generative text endpoint
          repetition_penalty  Float
          stream_options do
            include_usage     [ TrueClass, FalseClass ]
          end

        end

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
            error_type: error_type.to_s,
            error: parsed_body[ :error ][ :code ] || error_type.to_s,
            error_description: parsed_body[ :error ][ :message ] || error_description
          }
        elsif response.headers[ 'content-type' ].start_with?( 'text/plain' ) &&
              response.body && response.body.length > 0
          result[ :error_description ] = response.body
        end

        result

      end

    end

  end
end
