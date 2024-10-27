module Intelligence
  class Conversation 

    include DynamicSchema::Definable 
    include DynamicSchema::Buildable 

    schema do
      system_message    default: { role: :system }, &Message.schema  
      message           as: :messages, array: true, &Message.schema
    end

    attr_reader   :system_message
    attr_reader   :messages
    attr_reader   :tools

    def initialize( attributes = nil )
 
      @messages = []
      @tools = []
      if attributes
        if attributes[ :system_message ]&.any? 
          system_message = Message.new( 
            attributes[ :system_message ][ :role ],  
            attributes[ :system_message ]
          )
          @system_message = system_message unless system_message.empty?
        end

        attributes[ :messages ]&.each do | message_attributes |
          @messages << Message.new( message_attributes[ :role ], message_attributes )
        end
      end
      
    end

    def has_system_message?
      ( @system_message || false ) && !@system_message.empty?
    end

    def has_messages?
      !@messages.empty?
    end

    def has_tools?
      !@tools.empty?
    end

    def system_message=( message )
      raise ArgumentError, "The system message must be a Intelligence::Message." \
        unless message.is_a?( Intelligence::Message )
      raise ArgumentError, "The system message MUST have a role of 'system'." \
        unless message.role == :system
      @system_message = message
    end

    def append_message( *messages )
      @messages.concat( messages.flatten )
      self 
    end

    alias :<< :append_message

    def append_tool( *tools )
      @tools.concat( tools.flatten )
      self 
    end

    def to_h
      result = {}
      result[ :system_message ] = @system_message.to_h if @system_message
      result[ :messages ] = @messages.map { | m | m.to_h } 
      result[ :tools ] = @tools.map { | t | t.to_h } 
      result
    end

  end
end
