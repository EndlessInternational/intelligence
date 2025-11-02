module Intelligence

  #
  # class. ChatResult
  #
  # The ChatResult class encapsulates a successful result to a chat or stream request. A result 
  # includes an array of choices ( it is an array even if there is a single choice ) and the 
  # metrics associated with the generation of all result choices.
  #
  class ChatResult

    attr_reader :choices
    attr_reader :metrics

    def initialize( chat_attributes )
      raise 'A ChatResult must be initialized with attributes but got nil.' unless chat_attributes 

      @attributes = chat_attributes.dup
      @choices = ( @attributes.delete( :choices ) || [] ).map do | json_choice |
        ChatResultChoice.new( json_choice )
      end

      json_metrics = @attributes.delete( :metrics )
      @metrics = ChatMetrics.new( json_metrics ) if json_metrics
    end

    def id              = @attributes[ :id ]
    def user            = @attributes[ :user ]

    def message         = @choices.empty? ? nil : @choices.first.message
    def text            = self.message&.text || '' 
    def end_reason      = @choices.empty? ? nil : @choices.first.end_reason

    def key?(key)       = @attributes.key?(key)
    alias include? key?
    def size            = @attributes.size
    alias length size
    alias count size
    def empty?          = @attributes.empty? 

    def each( &block)   = @attributes.each( &block )
    def []( key )       = @attributes[ key ]

  end

end
