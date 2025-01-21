# this line will ensure your code can see the intelligence gem; if you have copied this example 
# to another directory be sure to change the next line to: require 'intelligence'
require_relative '../lib/intelligence'
require 'debug'

# this block of code builds and configures your adapter; in this case we have chosen google 
adapter = Intelligence::Adapter.build :google do 
  key             ENV[ 'GOOGLE_API_KEY' ]               # this is the google api key; here it is
                                                        # retrieved from the envionment
  chat_options do                                       
    model         'gemini-1.5-pro'                      # this is the google model we want to use
    max_tokens    512                                   # this is the maximum number of tokens we
                                                        # want the model to generate
    abilities do  
      google_search_retrieval                           # the grounding feature is 
                                                        # google_search_retrieval if you use a 1.5 
                                                        # model but just google_search if you 
                                                        # use a 2.0 model
    end
  end

end

# this line constructs a new request instance; you can reuse the request
request = Intelligence::ChatRequest.new( adapter: adapter )
# this line builds a conversation with a system and user message  
conversation = Intelligence::Conversation.build do
  system_message do 
    content text: "You are a highly efficient AI assistant. Provide clear, concise responses. " \
                  "There is no need to caveat your answers."
  end 
  message role: :user do 
    content text: ARGV[ 0 ] || 'Hello!'
  end
end
 
# this line makes the actual request to the api passing the conversaion we've built 
response = request.chat( conversation )

# this line checks if the request was successful; either way it will inclue a 'result'
if response.success?
  # if successful, the result will be a ChatResult instance which has a convenience text method
  # to easilly retrieve the response text 
  puts response.result.text 
else 
  # if not successful, the result be a ChatErrorResult instance which includes error information
  puts "Error: " + response.result.error_description
end 

