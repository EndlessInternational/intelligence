require_relative 'generic/adapter'
require 'net/http'
require 'uri'
require 'json'

module Intelligence
  module AzureOpenAi

    class Adapter < Generic::Adapter

      schema do
        # Azure OpenAI specific properties
        key                         String
        tenant_id                   String
        client_id                   String
        client_secret               String
        endpoint                    String, required: true
        api_version                 String, default: '2024-02-01'
        
        chat_options do
          # Standard OpenAI-compatible options
          model                     String, required: true 
          max_tokens                Integer, as: :max_completion_tokens
          temperature               Float
          top_p                     Float
          seed                      Integer
          stop                      String, array: true
          stream                    [ TrueClass, FalseClass ]
          frequency_penalty         Float
          presence_penalty          Float
          n                         Integer

          # Azure OpenAI variant properties
          max_completion_tokens     Integer

          # Azure OpenAI specific properties
          audio do 
            voice                   String 
            format                  String 
          end
          logit_bias
          logprobs                  [ TrueClass, FalseClass ]
          top_logprobs              Integer
          modalities                String, array: true 
          response_format do 
            type                    Symbol, in: [ :text, :json_schema ]
            json_schema
          end
          service_tier              String
          stream_options do
            include_usage           [ TrueClass, FalseClass ]
          end
          user 
          
          # Tool support
          tool                      array: true, as: :tools, &Tool.schema 
          tool_choice               arguments: :type do 
            type                    Symbol, in: [ :none, :auto, :required ]
            function                arguments: :name do 
              name                  Symbol 
            end 
          end 
          parallel_tool_calls       [ TrueClass, FalseClass ]
        end
      end

      def fetch_azure_access_token(tenant_id, client_id, client_secret)
        uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
        res = Net::HTTP.post_form(uri, {
          'client_id' => client_id,
          'client_secret' => client_secret,
          'scope' => 'https://cognitiveservices.azure.com/.default',
          'grant_type' => 'client_credentials'
        })
        raise res.body unless res.is_a?(Net::HTTPSuccess)
        JSON.parse(res.body)['access_token']
      end

      def chat_request_uri( options )
        options = merge_options( @options, build_options( options ) )
        endpoint = options[ :endpoint ]
        model = options.dig( :chat_options, :model )
        api_version = options[ :api_version ]

        raise ArgumentError.new( "An Azure OpenAI endpoint is required to build an Azure OpenAI chat request." ) \
          if endpoint.nil?
        raise ArgumentError.new( "A model is required to build an Azure OpenAI chat request." ) \
          if model.nil?

        # Azure OpenAI endpoint format: https://{endpoint}/openai/deployments/{model}/chat/completions?api-version={api_version}
        "#{endpoint}/openai/deployments/#{model}/chat/completions?api-version=#{api_version}"
      end

      def chat_request_headers( options = nil )
        options = merge_options( @options, build_options( options ) )

        result = {}
        tenant_id = options[ :tenant_id ]
        client_id = options[ :client_id ]
        client_secret = options[ :client_secret ]
        if tenant_id && client_id && client_secret
          token = fetch_azure_access_token(tenant_id, client_id, client_secret)
          result[ 'Authorization' ] = "Bearer #{token}"
        else
          key = options[ :key ] 
          raise ArgumentError.new( "An Azure OpenAI key is required to build an Azure OpenAI chat request." ) \
            if key.nil?
          result[ 'api-key' ] = key
        end
        result[ 'Content-Type' ] = 'application/json'
        result 
      end

      def chat_request_body( conversation, options = nil )
        tools = options&.delete( :tools ) || []
        options = merge_options( @options, build_options( options ) )
        
        # Remove model from the request body as it's in the URL for Azure OpenAI
        chat_options = options[ :chat_options ]&.dup || {}
        chat_options.delete( :model )

        # Use the parent implementation with cleaned options
        super( conversation, { tools: tools }.merge( options.merge( chat_options: chat_options ) ) )
      end

    end

  end
end 