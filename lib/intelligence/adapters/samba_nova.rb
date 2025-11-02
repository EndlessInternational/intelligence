require_relative 'generic/adapter'

module Intelligence
  module SambaNova

    class Adapter < Generic::Adapter

      DEFAULT_BASE_URI        = "https://api.sambanova.ai/v1"
      
      schema do 

        # normalized properties for all endpoints
        base_uri              String, default: DEFAULT_BASE_URI        
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
        error_type, error_description = to_error_response( response.status )
        result = {
          error_type: error_type.to_s,
          error_description: error_description
        }

        parsed_body = JSON.parse( response.body, symbolize_names: true ) rescue nil 
        if parsed_body && 
           parsed_body.respond_to?( :include? ) && parsed_body.include?( :error ) && 
           parsed_body[ :error ].is_a?( String )
          result[ :error_description ] = parsed_body[ :error ]
        elsif response.headers[ 'content-type' ].start_with?( 'text/plain' ) &&
              response.body && response.body.length > 0
          result[ :error_description ] = response.body
        end

        result
      end

    end

  end
end
