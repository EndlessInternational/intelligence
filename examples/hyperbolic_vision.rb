# this line will ensure your code can see the intelligence gem; if you have copied this example 
# to another directory be sure to change the next line to: require 'intelligence'
require_relative '../lib/intelligence'
# this line will include the mime types gem; be sure to install it: `gem install "mime-types"`
require 'mime-types'

# this block of code checks that you've provided a file path and that the file exists 
file_path = ARGV[ 0 ]
if file_path.nil? || !File.exist?( file_path )
  puts "Error: You have not specified a file or the file could not be found"
  exit 
end 

# this block of code obtains the file mime type and verfies that it is an image
file_mime_type = MIME::Types.type_for( file_path )&.first
if file_mime_type.nil? || file_mime_type.media_type != 'image'
  puts "Error: You have not specified an image file."
  exit
end
file_content_type = file_mime_type.content_type

# this block of code constructs a new Faraday connection  
connection = Faraday.new do | faraday |
  faraday.options.timeout = 100                        # read timout set to 60 seconds
  faraday.options.open_timeout = 2                     # connection open timeout set to 1 seconds

  # add other middleware or options as needed
  
  # create a default adapter
  faraday.adapter Faraday.default_adapter
end 

# this block of code builds and configures your adapter; in this case we have chosen hyperbolic 
adapter = Intelligence::Adapter.build :hyperbolic do 
  key             ENV[ 'HYPERBOLIC_API_KEY' ]           # this is the hyperbolic api key; here 
                                                        # it is retrieved from the envionment
  chat_options do                                       
    model         'Qwen/Qwen2-VL-7B-Instruct'          # this is the open ai model we want to use
    max_tokens    256                                   # this is the maximum number of tokens we
                                                        # want the model to generate
  end
end

# this line constructs a new request instance with the connection and adapter, the adapter is 
# required but you can omit the connection; you can reuse the request
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

