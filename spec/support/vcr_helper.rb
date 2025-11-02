require 'vcr'

SENSITIVE_URL_PARAMETERS = %w( 
  key
)

SENSITIVE_REQUEST_HEADERS = %w(
  x-api-key api-key
)

SENSITIVE_RESPONSE_HEADERS = %w(
  set-cookie Set-Cookie cf-ray request-id x-request-id x-cloud-trace-context 
  openai-organization
)

VCR.configure do | config |

  config.cassette_library_dir = File.join( __dir__, '..', 'fixtures', 'cassettes' )
  config.allow_http_connections_when_no_cassette = true

  # general
  config.filter_sensitive_data( '<TOKEN>') do | interaction |
    authorization = interaction.request.headers[ 'Authorization' ]&.first
    if authorization && match = authorization.match( /^Bearer\s+([^,\s]+)/ )
      match.captures.first
    end
  end

  config.before_record do | interaction |
    SENSITIVE_URL_PARAMETERS.each do | key |
      interaction.request.uri.gsub!( /(#{key}=)[^&]+/, "\\1<#{key.upcase}>" )
    end
    SENSITIVE_REQUEST_HEADERS.each do | header |
      interaction.request.headers[ header ]&.map! { "<#{header.upcase}>" }
    end
    SENSITIVE_RESPONSE_HEADERS.each do | header |
      interaction.response.headers[ header ]&.map! { "<#{header.upcase}>" }
    end
  end

end

CASSETTE_OPTIONS = {
  serialize_with: :json,
  match_requests_on: [ 
    :method,
    VCR.request_matchers.uri_without_params( *SENSITIVE_URL_PARAMETERS )
  ]
}
 
RSpec.shared_context 'vcr' do 
  
  around( :each ) do | example |
    if example.metadata[ :ignore_cassettes ]
      example.run
    else
      options = CASSETTE_OPTIONS.dup
      options[ :record ] = :all if example.metadata[ :record_cassettes ]
      VCR.use_cassette( example.metadata[ :full_description ], options ) do
        example.run
      end
    end
  end

end

