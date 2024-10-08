module Intelligence

  #
  # class. Conversation
  #
  class Conversation 

    attr_reader   :system_message
    attr_reader   :messages
    attr_reader   :tools

    def initialize( attributes = {} )
      @system_message = attributes[ :system_message ]&.dup
      @messages = attributes[ :messages ]&.dup || []
      @tools = attributes[ :tools ]&.dup || [] 
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

    def to_h
      result = {}
      result[ :system_message ] = @system_message.to_h if @system_message
      result[ :messages ] = @messages.map { | m | m.to_h } 
      result[ :tools ] = @tools.map { | t | t.to_h } 
      result
    end

  end

end
