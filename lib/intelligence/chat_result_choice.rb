module Intelligence

  class ChatResultChoice 

    attr_reader :message
    attr_reader :end_reason
    attr_reader :end_sequence

    def initialize( chat_choice_attributes )
      @end_reason = chat_choice_attributes[ :end_reason ]
      @end_sequence = chat_choice_attributes[ :end_sequence ]
      @message = build_message( chat_choice_attributes[ :message ] ) \
        if chat_choice_attributes[ :message ]
    end

  private 
  
    def build_message( json_message )
      message = Message.new( json_message[ :role ]&.to_sym || :assistant )
      json_message[ :contents ]&.each do | json_content |
        message << MessageContent.build( json_content[ :type ], json_content )
      end
      message 
    end

  end

end
