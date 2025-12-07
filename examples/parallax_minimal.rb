require_relative '../lib/intelligence'
adapter_options = {
  base_uri: 'http://localhost:4001/v1',
  chat_options: { 
    max_tokens: 2048 

  }
}

adapter = Intelligence::Adapter[ :parallax ].new( adapter_options )

request = Intelligence::ChatRequest.new( adapter: adapter )
response = request.chat( ARGV[ 0 ] || 'Hello!' ) 

if response.success?
  puts response.result.text 
else 
  puts "Error: " + response.result.error_description
end 

