require_relative 'generic/adapter'

module Intelligence
  module Ollama

    class Adapter < Generic::Adapter

      schema do
        # Ollama doesn't require a real API key, but the generic adapter expects one
        key                         String, default: 'ollama'
        
        # Ollama endpoint configuration
        endpoint                    String
        
        chat_options do
          # Standard OpenAI-compatible options that work with Ollama
          model                     String, required: true 
          max_tokens                Integer
          temperature               Float
          top_p                     Float
          seed                      Integer
          stop                      String, array: true
          stream                    [ TrueClass, FalseClass ]
          frequency_penalty         Float
          presence_penalty          Float
          n                         Integer
          
          # Tool support (varies by model)
          tool                      array: true, as: :tools, &Tool.schema 
          tool_choice               arguments: :type do 
            type                    Symbol, in: [ :none, :auto, :required ]
            function                arguments: :name do 
              name                  Symbol 
            end 
          end 
        end
      end

      def chat_request_uri( options )
        options = merge_options( @options, build_options( options ) )
        endpoint = options[ :endpoint ]
        
        raise ArgumentError.new( "An Ollama endpoint is required to build an Ollama chat request." ) \
          if endpoint.nil?

        "#{endpoint}/v1/chat/completions"
      end

      def chat_request_headers( options = nil )
        options = merge_options( @options, build_options( options ) )
        result = {}

        # Ollama doesn't require a real API key, just set Content-Type
        result[ 'Content-Type' ] = 'application/json'
        
        # Only add Authorization header if a real key is provided (not the default 'ollama')
        key = options[ :key ]
        if key && key != 'ollama'
          result[ 'Authorization' ] = "Bearer #{key}"
        end

        result 
      end

      def chat_request_body( conversation, options = nil )
        # Extract tools before merging options (following Azure OpenAI pattern)
        tools = options&.delete( :tools ) || []
        options = merge_options( @options, build_options( options ) )
        
        # Use the parent implementation with safely extracted tools
        super( conversation, { tools: tools }.merge( options ) )
      end

    end

  end
end 