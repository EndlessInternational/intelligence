require_relative 'generic'

module Intelligence
  module Azure
    class Adapter < Generic::Adapter      
      CHAT_COMPLETIONS_PATH = 'chat/completions'

      schema do 
	        # normalized properties, used by all endpoints
	        base_uri                    String, required: true
	        key                         String
	        api_version  								String, required: true, default: 'preview'
	        
	        # properties for generative text endpoints 
	        chat_options do 
	        
	          # normalized properties for openai generative text endpoint
	          model                     String, requried: true 
	          max_tokens                Integer, in: (0...)
	          temperature               Float, in: (0..1)
	          top_p                     Float, in: (0..1)
	          seed                      Integer
	          stop                      String, array: true
	          stream                    [ TrueClass, FalseClass ]

	          frequency_penalty         Float, in: (-2..2)
	          presence_penalty          Float, in: (-2..2)

	          modalities                String, array: true 
	          response_format do 
	            # 'text' and 'json_schema' are the only supported types
	            type                    Symbol, in: [ :text, :json_schema ]
	            json_schema
	          end
	          
	          # tools
	          tool                      array: true, as: :tools, &Tool.schema 
	          # tool choice configuration 
	          #
	          # `tool_choice :none` 
	          # or 
	          # ```
	          # tool_choice :function do 
	          #   function :my_function 
	          # end  
	          # ```
	          tool_choice               arguments: :type do 
	            type                    Symbol, in: [ :none, :auto, :required ]
	            function                arguments: :name do 
	              name                  Symbol 
	            end 
	          end 
	          # the parallel_tool_calls parameter is only allowed when 'tools' are specified
	          parallel_tool_calls       [ TrueClass, FalseClass ]

	        end
	      end

      def chat_request_uri( options = nil )
        options = merge_options( @options, build_options( options ) )
        base_uri = options[ :base_uri ]
        if base_uri
          # because URI join is dumb
          base_uri = ( base_uri.end_with?( '/' ) ? base_uri : base_uri + '/' ) 
          uri = URI.join( base_uri, CHAT_COMPLETIONS_PATH )

					api_version = options[ :api_version ] || options[ 'api-version' ]
    			uri.query   = [ uri.query, "api-version=#{ api_version }" ].compact.join( '&' ) 

    			uri
        else
          raise 'The Azure adapter requires a base_uri.' 
        end
      end

      def chat_request_headers( options = {} )
        options = merge_options( @options, build_options( options ) )
        result = {}

        key = options[ :key ] 

        raise ArgumentError.new( "An Azure key is required to build an Azure request." ) \
          if key.nil?

        result[ 'Content-Type' ] = 'application/json'
        result[ 'api-key' ] = key
        result 
      end

    end
  end
end