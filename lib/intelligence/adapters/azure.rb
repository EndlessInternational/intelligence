require_relative 'generic/adapter'
require 'net/http'
require 'uri'
require 'json'

module Intelligence
  module Azure
    class Adapter < Generic::Adapter

      CHAT_COMPLETIONS_PATH = 'openai/deployments'

      schema do
        base_uri                    String, required: true
        key                         String
        tenant_id                   String
        client_id                   String
        client_secret               String
        api_version                 String, required: true, default: '2024-10-21'

        chat_options do
          model                     String, required: true
          max_tokens                Integer, as: :max_completion_tokens
          temperature               Float, in: (0..1)
          top_p                     Float, in: (0..1)
          seed                      Integer
          stop                      String, array: true
          stream                    [ TrueClass, FalseClass ]

          frequency_penalty         Float, in: (-2..2)
          presence_penalty          Float, in: (-2..2)

          modalities                String, array: true
          response_format do
            type                    Symbol, in: [ :text, :json_schema ]
            json_schema
          end

          max_completion_tokens     Integer

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

      def chat_request_uri( options = nil )
        options = merge_options( @options, build_options( options ) )
        base_uri = options[ :base_uri ]
        model = options.dig( :chat_options, :model )
        api_version = options[ :api_version ]

        raise ArgumentError.new( "An Azure base_uri is required to build an Azure chat request." ) \
          if base_uri.nil?
        raise ArgumentError.new( "A model is required to build an Azure chat request." ) \
          if model.nil?

        base_uri = ( base_uri.end_with?( '/' ) ? base_uri : base_uri + '/' )
        "#{base_uri}#{CHAT_COMPLETIONS_PATH}/#{model}/chat/completions?api-version=#{api_version}"
      end

      def chat_request_headers( options = {} )
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
          raise ArgumentError.new( "An Azure key is required to build an Azure request." ) \
            if key.nil?
          result[ 'api-key' ] = key
        end

        result[ 'Content-Type' ] = 'application/json'
        result
      end

      def chat_request_body( conversation, options = nil )
        tools = options&.delete( :tools ) || []
        options = merge_options( @options, build_options( options ) )

        chat_options = options[ :chat_options ]&.dup || {}
        chat_options.delete( :model )

        super( conversation, { tools: tools }.merge( options.merge( chat_options: chat_options ) ) )
      end

    end
  end
end