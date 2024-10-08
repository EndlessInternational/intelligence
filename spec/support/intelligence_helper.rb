module IntelligenceHelper

  def adapter_key( env_key )
    raise "An #{env_key} must be defined in the environment." unless ENV[ env_key ]
    ENV[ env_key ]
  end

  def adapter_connection 
    Faraday.new do | builder | 
      builder.adapter Faraday.default_adapter 
      builder.use VCR::Middleware::Faraday 
    end
  end 

  def create_conversation( *messages )

    system_message = Intelligence::Message.new(
      :system,
      :text,
      text: <<~SYSMSG.strip
        You are integrated into a test platform. It is very important that you answer 
        succinctly and always provide the text in the requested format without any additional 
        text. 
      SYSMSG
    )

    conversation_messages = []

    messages.each_with_index do | message, index |
      conversation_messages << Intelligence::Message.new( 
        index.even? ? :user : :assistant, 
        :text, text: message 
      )
    end

    Intelligence::Conversation.new(
      system_message: system_message,
      messages: conversation_messages
    )
  end

  def build_text_message( role, text )
    Intelligence::Message.new( role, :text, text: text )
  end

  def build_text_content( role, text )
    Intelligence::MessageContent::Text.new( text  )
  end
  
  def build_binary_content( filepath )
    content_type = MIME::Types.type_for( filepath ).first.to_s
    bytes = File.binread( filepath )
    Intelligence::MessageContent::Binary.new( content_type: content_type, bytes: bytes  )
  end

  def create_and_make_chat_request( adapter, conversation )
    Intelligence::ChatRequest.new( connection: adapter_connection, adapter: adapter ).chat( conversation )
  end

  def create_and_make_stream_request( adapter, conversation, &block )
    Intelligence::ChatRequest.new( connection: adapter_connection, adapter: adapter ).stream( conversation ) do | request |
      request.receive_result do | result |
        block.call( result )
      end
    end
  end

  def message_contents_to_text( message )
    text = ''
    message.contents.each do | content | 
      text += content.text if content.is_a?( Intelligence::MessageContent::Text )
    end
    text
  end

  def response_error_description( response )
    ( response&.result&.respond_to?( :error_description ) ? response.result.error_description : nil ) || ''
  end

end

RSpec.configure do | config |
  config.include IntelligenceHelper
end
