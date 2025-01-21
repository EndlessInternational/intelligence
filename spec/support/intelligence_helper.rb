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

  def create_conversation_without_system_message( *texts )
    Intelligence::Conversation.build do 
      texts.each_with_index do | _text, index |
        message do 
          role index.even? ? :user : :assistant
          content do 
            text _text 
          end 
        end 
      end 
    end 
  end

  def create_conversation( *texts )
    Intelligence::Conversation.build do 
      system_message do  
        content do 
          text %Q(
            You are integrated into a test platform. It is very important that you answer 
            succinctly and always provide the text in the requested format without any additional 
            text. 
          )
        end 
      end
      texts.each_with_index do | _text, index |
        message do 
          role index.even? ? :user : :assistant
          content do 
            text _text 
          end 
        end 
      end 
    end 
  end

  def build_text_message( _role, _text )
    Intelligence::Message.build! do 
      role _role  
      content do 
        text _text
      end 
    end
  end

  def build_text_content( text )
    Intelligence::MessageContent::Text.build!( text: text )
  end
  
  def build_binary_content( filepath )
    content_type = MIME::Types.type_for( filepath ).first.to_s
    bytes = File.binread( filepath )
    Intelligence::MessageContent::Binary.build!( content_type: content_type, bytes: bytes  )
  end

  def create_and_make_chat_request( adapter, conversation, options = nil )
    request = Intelligence::ChatRequest.new( connection: adapter_connection, adapter: adapter )
    request.chat( conversation, options )
  end

  def create_and_make_stream_request( adapter, conversation, options = nil, &block )
    request = Intelligence::ChatRequest.new( connection: adapter_connection, adapter: adapter )
    request.stream( conversation, options ) do | request |
      request.receive_result do | result |
        block.call( result )
      end
    end
  end

  def message_contents_to_text( message )
    text = ''
    message.contents.each do | content |
      text += ( content.text || '' ) if content.is_a?( Intelligence::MessageContent::Text )
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
