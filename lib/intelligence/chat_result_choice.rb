module Intelligence

  class ChatResultChoice 

    attr_reader :message
    attr_reader :end_reason
    attr_reader :end_sequence

    def initialize( chat_choice_attributes )
      @attributes = chat_choice_attributes.dup
      @end_reason = @attributes.delete( :end_reason )
      @end_sequence = @attributes.delete( :end_sequence )

      message = @attributes.delete( :message )
      @message = build_message( message ) if message
    end

    def key?(key)       = @attributes.key?(key)
    alias include? key?
    def size            = @attributes.size
    alias length size
    alias count size
    def empty?          = @attributes.empty? 

    def each( &block)   = @attributes.each( &block )
    def []( key )       = @attributes[ key ]

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
