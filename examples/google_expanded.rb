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
# this line makes the actual request to the api and returns a response
response = request.chat( conversation )

# this line checks if the request was successful; either way it will inclue a 'result'
if response.success?
  # if successful, the result will be a ChatResult instance
  result = response.result 
  # every successful result has a collection of choices ( typically there is only one but some
  # adapters can return n result choices simultanously ); a choice is an instance of 
  # ChatResultChoice
  choices = result.choices 
  # we will select the first choice, as we expect only one 
  choice = choices.first 
  # every choice has a message 
  message = choice.message 
  # every message has a number of content items we can iterate through 
  message.each_content do | content |
    # finally we can output the text of the content; although we only expect text back from 
    # the model in some cases ( such as when tools are used ) it may respond with other content 
    # so we check to make sure we are only displaying text content 
    puts content.text if content.is_a?( Intelligence::MessageContent::Text ) 
  end
else 
  # if not successful, the result will be a ChatErrorResult instance which includes error 
  # information
  error_result = response.error_result
  puts "Error: " + error_result.error_description
end 

