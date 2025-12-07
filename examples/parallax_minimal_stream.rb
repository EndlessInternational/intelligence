require_relative '../lib/intelligence'

adapter_options = {
  base_uri: 'http://localhost:4001/v1',
  chat_options: { 
    max_tokens: 2048,
    stream: true 
  }
}

adapter = Intelligence::Adapter[ :parallax ].new( adapter_options )
request = Intelligence::ChatRequest.new( adapter: adapter )

response = request.stream( ARGV[ 0 ] || 'Hello!' ) do | request |
  request.receive_result do | result |
    print result.text
    if result.choices.first.end_reason
      print "\n"
    end
   end
end

unless response.success?
  puts "Error: " + response.result.error_description
end 

