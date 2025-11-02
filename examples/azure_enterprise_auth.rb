require 'intelligence'

# Example: Azure OpenAI with Enterprise Authentication (OAuth 2.0 Client Credentials)
# This demonstrates how to use Azure Active Directory for enterprise authentication

# Configuration using enterprise credentials
azure_enterprise = Intelligence::Adapter.build! :azure do
  base_uri ENV['AZURE_OPENAI_ENDPOINT']

  # Enterprise authentication (preferred for enterprise environments)
  tenant_id     ENV['AZURE_TENANT_ID']
  client_id     ENV['AZURE_CLIENT_ID']
  client_secret ENV['AZURE_CLIENT_SECRET']

  api_version '2024-02-01'

  chat_options do
    model 'gpt-4o'  # Azure deployment name
    max_tokens 256
    temperature 0.7
  end
end

# Alternative: Using API key authentication (fallback)
azure_api_key = Intelligence::Adapter.build! :azure do
  base_uri ENV['AZURE_OPENAI_ENDPOINT']
  key ENV['AZURE_OPENAI_API_KEY']
  api_version '2024-02-01'

  chat_options do
    model 'gpt-4o'
    max_tokens 256
    temperature 0.7
  end
end

# Test the enterprise authentication
conversation = Intelligence::Conversation.build do
  system_message do
    content text: "You are a helpful AI assistant."
  end

  message do
    role :user
    content text: "Explain the benefits of using enterprise authentication with Azure OpenAI."
  end
end

request = Intelligence::ChatRequest.new(adapter: azure_enterprise)
response = request.chat(conversation)

if response.success?
  puts "Enterprise Authentication Response:"
  puts response.result.text
else
  puts "Error: #{response.result.error_description}"
end