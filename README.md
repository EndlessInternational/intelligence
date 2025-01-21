# Intelligence

Intelligence is a lightweight yet powerful Ruby gem that provides a uniform interface for 
interacting with large language and vision model APIs across multiple vendors. It allows 
you to seamlessly integrate with services from OpenAI, Anthropic, Google, Mistral, Cerebras, 
Groq, Hyperbolic, Samba Nova, Together AI, and others, while maintaining a consistent API 
across all providers. 

The gem operates with minimal dependencies and doesn't require vendor SDK installation, 
making it easy to switch between providers or work with multiple providers simultaneously.

```ruby
require 'intelligence'

adapter = Intelligence::Adapter.build :open_ai do 
  key             ENV[ 'OPENAI_API_KEY' ]               
  chat_options do                                       
    model         'gpt-4o'                             
    max_tokens    256                                   
  end
end

request = Intelligence::ChatRequest.new( adapter: adapter )
conversation = Intelligence::Conversation.build do
  system_message do 
    content text: "You are a highly efficient AI assistant. Provide clear, concise responses."
  end 
  message role: :user do 
    content text: ARGV[ 0 ] || 'Hello!'
  end
end
 
response = request.chat( conversation )

if response.success?
  puts response.result.text 
else 
  puts "Error: " + response.result.error_description
end 
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'intelligence'
```

Then execute:

```bash
$ bundle install
```

Or install it directly:

```bash
$ gem install intelligence
```

## Usage

### Fundamentals

The core components of Intelligence are adapters, requests and responses. An adapter encapsulates
the differences between different API vendors, allowing you to use requests and responses 
uniformly.

You retrieve an adapter for a specific vendor, configure it with a key, model and associated  
parameters and then make a request by calling either the `chat` or `stream` methods.

```ruby
require 'intelligence'

# configure the adapter with your API key and model settings
adapter = Intelligence::Adapter[ :google ].new(
  key: ENV[ 'GOOGLE_API_KEY' ],
  chat_options: { 
    model: 'gemini-1.5-flash-002', 
    max_tokens: 256 
  }
)

# create a request instance, passing the adapter 
request = Intelligence::ChatRequest.new( adapter: adapter )

# make the request and handle the response
response = request.chat( "What is the capital of France?" )

if response.success?
  puts response.result.text
else
  puts "Error: #{response.result.error_description}"
end
```

The `response` object is a `Faraday` response with an added method: `result`. If a response is 
successful `result` returns a `ChatResult`. If it is not successful it returns a 
`ChatErrorResult`. You can use the `Faraday` method `success?` to determine if the response is 
successful.

### Results

When you make a request using Intelligence, the response includes a `result` that provides 
structured access to the model's output. 

- A `ChatResult` contains one or more `choices` (alternate responses from the model). The 
  `choices` method returns an array of `ChatResultChoice` instances. `ChatResult` also 
  includes a `metrics` methods which provides information about token usage for the request.
- A `ChatResultChoice` contains a `message` from the assistant and an `end_result` which
  indicates how the response ended:
  - `:ended` means the model completed its response normally
  - `:token_limit_exceeded` means the response hit the token limit ( `max_tokens` )
  - `:end_sequence_encountered` means the response hit a stop sequence
  - `:filtered` means the content was filtered by the vendors safety settings or protocols 
  - `:tool_called` means the model is requesting to use a tool
- The `Message` in each choice contains one or more content items, typically text but 
  potentially tool calls or other content types.

While the convenience method `text` used in the previous example is useful for simple cases, 
you will typically want to work with the full response structure.

```ruby
adapter = Intelligence::Adapter[ :google ].new(
  key: ENV[ 'GOOGLE_API_KEY' ],
  chat_options: { 
    model: 'gemini-1.5-flash-002', 
    max_tokens: 256 
  }
)

request = Intelligence::ChatRequest.new( adapter: adapter )
response = request.chat( "What are three interesting facts about ruby gemstones?" )

if response.success?
  result = response.result  # this is a ChatResult
  
  # iterate through the model's choices
  result.choices.each do | choice |
    # check why the response ended
    puts "Response ended because: #{choice.end_reason}"
    
    # work with the message
    message = choice.message
    puts "Message role: #{message.role}"
    
    # examine each piece of content
    message.each_content do | content |
      puts content.text if content.is_a?( Intelligence::MessageContent::Text )
    end
  end
  
  # check token usage if metrics are available
  if result.metrics
    puts "Input tokens: #{result.metrics.input_tokens}"
    puts "Output tokens: #{result.metrics.output_tokens}"
    puts "Total tokens: #{result.metrics.total_tokens}"
  end
else
  # or alternativelly handle the error result 
  puts "Error: #{response.result.error_description}"
end
```

The `ChatResult`, `ChatResultChoice` and `Message` all provide the `text` convenience 
method which return the text. 

### Conversations, Messages, and Content

Intelligence organizes interactions with models using three main components:

- **Conversations** are collections of messages that represent a complete interaction with a 
  model. A conversation can include an optional system message that sets the context, a series
  of back-and-forth messages between the user and assistant and any tools the model may call.

- **Messages** are individual communications within a conversation. Each message has a role 
  (`:system`, `:user`, or `:assistant`) that identifies its sender and can contain multiple 
  pieces of content.

- **Content** represents the actual data within a message. This can be text 
  ( `MessageContent::Text` ), binary data like images ( `MessageContent::Binary` ), references 
  to files ( `MessageContent::File` ) or tool calls or tool results ( `MessageContent::ToolCall`
  or `MessageContent::ToolResult` respectivelly ).

In the previous examples we used a simple string as an argument to `chat`. As a convenience,
the `chat` methods builds a coversation for you from a String but, typically, you will construct
a coversation instance ( `Coversation` ) and pass that to the chat or stream methods. 

The following example expands the minimal example, building a conversation, messages and content:

```ruby
# create an adapter as before
adapter = Intelligence::Adapter[ :google ].new(
  key: ENV[ 'GOOGLE_API_KEY' ],
  chat_options: { model: 'gemini-1.5-flash-002', max_tokens: 256 }
)

# create a conversation
conversation = Intelligence::Conversation.new

# add a system message (optional but recommended)
system_message = Intelligence::Message.new( :system )
system_message << Intelligence::MessageContent::Text.new(
  text: "You are a helpful coding assistant."
)
conversation.system_message = system_message

# add a user message
user_message = Intelligence::Message.new( :user )
user_message << Intelligence::MessageContent::Text.new(
  text: "How do I read a file in Ruby?"
)
conversation.messages << user_message

# make the request
request = Intelligence::ChatRequest.new( adapter: adapter )
response = request.chat( conversation )

if response.success?
  puts response.result.text
else
  puts "Error: #{response.result.error_description}"
end
```

The hierarchical nature of these components makes it easy to organize and access your interaction 
data. A conversation acts as a container for messages, and each message acts as a container for 
content items. This structure allows for rich interactions that can include multiple types of 
content in a single message.

You can examine the contents of a conversation by iterating through its messages and their content:

```ruby
# iterate through messages
conversation.messages.each do |message|
  puts "Role: #{message.role}"
  
  # each message can have multiple content items
  message.each_content do |content|
    case content
    when Intelligence::MessageContent::Text
      puts "Text: #{content.text}"
    when Intelligence::MessageContent::Binary
      puts "Binary content of type: #{content.content_type}"
    when Intelligence::MessageContent::File
      puts "File reference: #{content.uri}"
    end
  end
end

# remeber that, alternatively, you can use convenience methods for quick text access
puts message.text  # combines all text content in a messages with newlines
```
### Continuing Conversations / Maintaining Context

To continue a conversation with the model, we can add the model's response and our follow-up 
message to the conversation:

```ruby
# get the previous response
if response.success?
  # add the assistant's response to our conversation
  assistant_message = response.result.message
  conversation.messages << assistant_message
  
  # add another user message for follow-up
  follow_up = Intelligence::Message.new( :user )
  follow_up << Intelligence::MessageContent::Text.new(
    text: "How do I write to that file?"
  )
  conversation.messages << follow_up
  
  # make another request with the updated conversation
  response = request.chat( conversation )
  
  if response.success?
    puts response.result.text
  end
end
```

This pattern allows you to maintain context across multiple interactions with the model. Each 
request includes the full conversation history, helping the model provide more contextually 
relevant responses.

### Builders

For more readable configuration, Intelligence provides builder syntax for both adapters and 
conversations.

```ruby
adapter = Intelligence::Adapter.build! :google do
  key ENV['GOOGLE_API_KEY']
  chat_options do
    model 'gemini-1.5-flash-002'
    max_tokens 256
    temperature 0.7
  end
end
```

Similarly, you can use builders to construct conversations with multiple messages.

```ruby
conversation = Intelligence::Conversation.build do
  system_message do
    content text: "You are a knowledgeable historian specializing in ancient civilizations."
  end
  
  message do
    role :user
    content text: "What were the key factors in the fall of the Roman Empire?"
  end
end

request = Intelligence::ChatRequest.new( adapter: adapte r)
response = request.chat( conversation )
```

## Binary and File Content

Intelligence supports vision models through binary and file content types.

```ruby
require 'intelligence'
require 'mime-types'

adapter = Intelligence::Adapter.build! :open_ai do
  key ENV[ 'OPENAI_API_KEY' ]
  chat_options do
    model 'gpt-4-vision-preview'
    max_tokens 256
  end
end

# Using binary content for local images
conversation = Intelligence::Conversation.build do
  message do
    role :user
    content text: "What's in this image?"
    content do
      type :binary
      content_type 'image/jpeg'
      bytes File.binread( 'path/to/image.jpg' )
    end
  end
end

request = Intelligence::ChatRequest.new( adapter: adapter )
response = request.chat( conversation )
```

For remote images, you can use file content instead of binary content:

```ruby
conversation = Intelligence::Conversation.build do
  message do
    role :user
    content text: "Analyze this image"
    content do
      type :file
      content_type 'image/jpeg'
      uri 'https://example.com/image.jpg'
    end
  end
end
```

## Tools

Intelligence supports tool/function calling capabilities, allowing models to 
use defined tools during their response.

```ruby
adapter = Intelligence::Adapter.build! :anthropic do
  key ENV['ANTHROPIC_API_KEY']
  chat_options do
    model 'claude-3-5-sonnet-20240620'
    max_tokens 1024
  end
end

# Define a tool for getting weather information
weather_tool = Intelligence::Tool.build! do
  name :get_weather
  description "Get the current weather for a specified location"
  argument name: :location, required: true, type: 'object' do
    description "The location for which to retrieve weather information"
    property name: :city, type: 'string', required: true do
      description "The city or town name"
    end
    property name: :state, type: 'string' do
      description "The state or province (optional)"
    end
    property name: :country, type: 'string' do
      description "The country (optional)"
    end
  end
end

# Create a conversation with the tool
conversation = Intelligence::Conversation.build do
  system_message do
    content text: "You can help users check weather conditions."
  end
  
  message do
    role :user
    content text: "What's the weather like in Paris, France?"
  end
end

request = Intelligence::ChatRequest.new( adapter: adapter )
response = request.chat( conversation, tools: [ weather_tool ] )

# Handle tool calls in the response
if response.success?
  result.choices.each do |choice|
    choice.message.each_content do |content|
      if content.is_a?(Intelligence::MessageContent::ToolCall)
        # Process the tool call
        if content.tool_name == :get_weather
          # Make actual weather API call here
          weather_data = fetch_weather(content.tool_parameters[:location])
          
          # Send tool result back to continue the conversation
          conversation.messages << Intelligence::Message.build! do
            role :user
            content do
              type :tool_result
              tool_call_id content.tool_call_id
              tool_result weather_data.to_json
            end
          end
        end
      end
    end
  end
end
```

Tools are defined using the `Intelligence::Tool.build!` method, where you specify the tool's 
name, description, and its argument schema. Arguments can have nested properties with their 
own descriptions and requirements. Once defined, tools are added to conversations and can be 
used by the model during its response. 

Note that not all providers support tools, and the specific tool capabilities may vary between 
providers. Today, OpenAI, Anthropic, Google, Mistral, and Together AI support tools. In general
all these providers support tools in an identical manner but as of this writing Google does not
support 'complex' tools which take object parameters.

## Streaming Responses

The `chat` method, while straightforward in implementation, can be time consuming ( especially 
when using modern 'reasoning' models like OpenAI O1 ). The alternative is to use the `stream` 
method which will receive results as these are generated by the model. 

```ruby
adapter = Intelligence::Adapter.build! :anthropic do
  key ENV['ANTHROPIC_API_KEY']
  chat_options do
    model 'claude-3-5-sonnet-20240620'
    max_tokens 1024
    stream true
  end
end

request = Intelligence::ChatRequest.new(adapter: adapter)

response = request.stream( "Tell me a story about a robot." ) do | request |
  request.receive_result do | result |
    # result is a ChatResult object with partial content
    print result.text 
    print "\n" if result.choices.first.end_reason
  end
end
```

Notice that in this approach you will receive multiple results ( `ChatResult` instances )
each with a fragment of the generation. The result always includes a `message` and will 
include `contents` as soon as any content is received. The `contents` is always positionally 
consitent, meaning that if a model is, for example, generating text followed by several 
tool calls you may receive a single text content initially, then the text content and a tool, 
and then subsequent tools, even after the text has been completely generated. 

Remember that every `result` contains only a fragment of content and it is possible that 
any given fragment is completely blank ( that is, it is possible for the content to be 
present in the result but all of it's fields are nil ). 

While you will likelly want to immediatelly output any generated text but, as practical matter, 
tool calls are not useful until full generated. To assemble tool calls ( or the text ) from
the text fragments you may use the content items `merge` method. 

```ruby
request = Intelligence::ChatRequest.new( adapter: adapter )

contents = []
response = request.stream( "Tell me a story about a robot." ) do | request |
  request.receive_result do | result |
    choice = result.choices.first
    contents_fragments = choice.message.contents 
    contents.fill( nil, contents.length..(contents_fragments.length - 1) )

    contents_fragments.each_with_index do | contents_fragment, index |
      if contents_fragment.is_a?( Intelligence::MessageContent::Text )
        # here we need the `|| ''` because the text of the fragment may be nil 
        print contents_fragment.text 
      else 
        contents[ index ] = contents[ index ].nil? ? 
          contents_fragment : 
          contents[ index ].merge( contents_fragment )
      end 
    end

  end
end
```

In the above example we construct an array to receive the content. As the content fragments 
are streamed we will immediatelly output generated text but other types of content ( today 
it could only be instances of `Intelligence::MessageContent::ToolCall' ) are individualy 
combined in the `contents` array. You can simply iterate though the array and then retrieve 
and take action for any of the tool calls. 

Note also that the `result` will only include a non-nil `end_reason` as the last ( or one 
of the last, `result` instances to be received ).

Finally note that the streamed `result` is always a `ChatResult`, never a `ChatErrorResult`. 
If an error occurs, the request itself will fail and you will receive this as part of 
`response.result`. 

## Provider Switching

One of Intelligence's most powerful features is the ability to easily switch between providers:

```ruby
def create_adapter(provider, api_key, model)
  Intelligence::Adapter.build! provider do
    key api_key
    chat_options do
      model model
      max_tokens 256
    end
  end
end

# Create adapters for different providers
anthropic = create_adapter(:anthropic, ENV['ANTHROPIC_API_KEY'], 'claude-3-5-sonnet-20240620')
google = create_adapter(:google, ENV['GOOGLE_API_KEY'], 'gemini-1.5-pro-002')
openai = create_adapter(:open_ai, ENV['OPENAI_API_KEY'], 'gpt-4o')

# Use the same conversation with different providers
conversation = Intelligence::Conversation.build do
  system_message do
    content text: "You are a helpful assistant."
  end
  message do
    role :user
    content text: "Explain quantum entanglement in simple terms."
  end
end

[anthropic, google, open_ai].each do |adapter|
  request = Intelligence::ChatRequest.new(adapter: adapter)
  response = request.chat(conversation)
  puts "#{adapter.class.name} response: #{response.result.text}"
end
```

## License

This gem is available as open source under the terms of the MIT License.
