# this line will ensure your code can see the intelligence gem; if you have copied this example 
# to another directory be sure to change the next line to: require 'intelligence'
require_relative '../lib/intelligence'

# this block of code builds and configures your adapter; in this case we have chosen google 
adapter = Intelligence::Adapter.build! :google do 
  key             ENV[ 'GOOGLE_API_KEY' ]               # this is the google api key; here it is
                                                        # retrieved from the envionment
  chat_options do                                       

    model         'gemini-1.5-pro'                      # this is the google model we want to use
    max_tokens    256                                   # this is the maximum number of tokens we
                                                        # want the model to generate
    stream        true
  end
end

# this line creates an conversation, which is a collection of messages we want to send to the 
# model together 
conversation = Intelligence::Conversation.new 

# here we are creating a new system message we will add to the conversation 
message = Intelligence::Message.new( :system )
# here we are creating a new text content item  
content = Intelligence::MessageContent.build( :text, text: 'You are a helpful assistant.' )
# here we add the content to the message
message << content 
# and finally we will set the system message for the conversation 
conversation.system_message = message  

# here we will add a user message, this time using a builder to make the code less verbose
conversation << Intelligence::Message.build! do 
  role :user
  content text: ARGV[ 0 ] || 'Hello!'
end

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
