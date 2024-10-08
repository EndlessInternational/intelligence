# this line will ensure your code can see the intelligence gem; if you have copied this example 
# to another directory be sure to change the next line to: require 'intelligence'
require_relative '../lib/intelligence'

# this code defines the adapter options; we're adding the open ai api key from the environment
# plus a gtp-4o model and a limiting tokens per response to 256
adapter_options = {
  key: ENV[ 'OPENAI_API_KEY' ],
  chat_options: { model: 'gpt-4o', max_tokens: 256 }
}

# this code builds and configures your adapter; in this case we have chosen open_ai to match 
# our options 
adapter = Intelligence::Adapter[ :open_ai ].new( adapter_options )

# this line creates the request instance; you can reuse the request
request = Intelligence::ChatRequest.new( adapter: adapter )
# this makes the actual request to the api, taking in a 'conversation' and returning a response;
# as a convenience you can pass a string to this method and conversation will be created for you
response = request.chat( ARGV[ 0 ] || 'Hello!' ) 

# this line checks if the request was successful; either way it will inclue a 'result'
if response.success?
  # if successful, the result will be a ChatResult instance which has a convenience text method
  # to easilly retrieve the response text 
  puts response.result.text 
else 
  # if not successful, the result be a CharErrorResult instance which includes error information
  puts "Error: " + response.result.error_description
end 

