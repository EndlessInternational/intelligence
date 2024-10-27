# this line will ensure your code can see the intelligence gem; if you have copied this example 
# to another directory be sure to change the next line to: require 'intelligence'
require_relative '../lib/intelligence'
# this line will include the mime types gem; be sure to install it: `gem install "mime-types"`
require 'mime-types'

file_path = ARGV[ 0 ]
if file_path.nil? || !File.exist?( file_path )
  puts "Error: You have not specified a file or the file could not be found"
  exit 
end 
file_mime_type = MIME::Types.type_for( file_path )&.first
if file_mime_type.nil?
  puts "Error: You have not specified a recognizable file."
  exit
end
file_content_type = file_mime_type.content_type

# this block of code builds and configures your adapter; in this case we have chosen google 
adapter = Intelligence::Adapter.build :google do 
  key             ENV[ 'GOOGLE_API_KEY' ]               # this is the google api key; here it is
                                                        # retrieved from the envionment
  chat_options do                                       
    model         'gemini-1.5-flash-8b'                 # this is the open ai model we want to use
    max_tokens    8192                                  # this is the maximum number of tokens we
                                                        # want the model to generate
  end
end

# this line constructs a new request instance; you can reuse the request
request = Intelligence::ChatRequest.new( adapter: adapter )
# this line builds a conversation with a system and user message  
conversation = Intelligence::Conversation.build do
  system_message do 
    content text: "You are a highly efficient AI assistant. Provide clear, concise responses."
  end 
  message role: :user do 
    content text: ARGV[ 1 ] || 'What do you see in this image?'
    content do 
      type :binary 
      content_type file_content_type
      bytes File.binread( file_path )
    end
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

