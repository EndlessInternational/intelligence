# this line will ensure your code can see the intelligence gem; if you have copied this example 
# to another directory be sure to change the next line to: require 'intelligence'
require_relative '../lib/intelligence'

# this code defines the adapter options; we're adding the open ai api key from the environment
# plus a gtp-4o model and a limiting tokens per response to 1024; we're also going to stream so
# we have to enable the stream option
adapter_options = {
  key: ENV[ 'OPENAI_API_KEY' ],
  chat_options: { model: 'gpt-4o', max_tokens: 1024, stream: true }
}

# this code builds and configures your adapter; in this case we have chosen open_ai to match 
# our options 
adapter = Intelligence::Adapter[ :open_ai ].new( adapter_options )

# this line creates the request instance; you can reuse the request
request = Intelligence::ChatRequest.new( adapter: adapter )

# this lines makes the actual request to the api with the 'conversation' as input; as a 
# convenience you can also pass a string which will be convered to a conversation; 
# the stream call also requries a block which receives the in-progress (Faraday) request
response = request.stream( ARGV[ 0 ] || 'Hello!' ) do | request |
  # the request, in turn, is used to receive the results as these arrive
  request.receive_result do | result |
    # the result will be an instance of a ChatResult which has a convenience text method 
    # that you can use to print the text received in the first choice of that result 
    print result.text

    # if we want to check if the stream is complete we can check the end_reason from the 
    # first choice ( any value that is not nil in end_reason means that this is the last 
    # result with content we will receive )
    if result.choices.first.end_reason
      print "\n"
    end
   end
end

# this line checks if the request was successful; either way it will inclue a 'result'
unless response.success?
  # if not successful, the result be a ChatErrorResult instance which includes error information
  puts "Error: " + response.result.error_description
end 

