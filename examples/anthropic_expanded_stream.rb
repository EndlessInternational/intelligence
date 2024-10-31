# this line will ensure your code can see the intelligence gem; if you have copied this example 
# to another directory be sure to change the next line to: require 'intelligence'
require_relative '../lib/intelligence'

# this block of code builds and configures your adapter; in this case we have chosen anthropic 
adapter = Intelligence::Adapter.build! :anthropic do 
  key             ENV[ 'ANTHROPIC_API_KEY' ]            # this is the anthropic api key; here 
                                                        # it is retrieved from the envionment
  chat_options do                                       

    model         'claude-3-5-sonnet-20240620'          # this is the anthropic model we want 
    max_tokens    1024                                  # this is the maximum number of tokens 
                                                        # we want the model to generate
    stream        true                                  # the stream option is required when 
                                                        # calling the stream method
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

# this lines makes the actual request to the api with the 'conversation' as input; 
# the stream call also requires a block which receives the in-progress (Faraday) request
response = request.stream( ARGV[ 0 ] || 'Hello!' ) do | request |

  # the request, in turn, is used to receive the results as these arrive
  request.receive_result do | result |
    # the result will be an instance of a ChatResult; every result has a collection of choices 
    # ( typically there is only one but some adapters can return n result choices simultanously ); 
    # a choice is an instance of ChatResultChoice
    choices = result.choices 
    # we will select the first choice, as we expect only one 
    choice = choices.first 
    # every choice has a message 
    message = choice.message 
    # every message has a number of content items we can iterate through 
    message.each_content do | content |
      # finally we can output the text of the content; although we only expect text back from 
      # the model in some cases ( such as when tools are used ) it may respond with other content 
      # so we check to make sure we are only displaying text content; remember this content is 
      # only a fragment of the response and in some cases the fragment will be entirelly empty
      print content.text || '' if content.is_a?( Intelligence::MessageContent::Text ) 
    end

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
  # if not successful, the result will be a ChatErrorResult instance which includes error 
  # information
  puts "Error: " + response.result.error_description
end 

