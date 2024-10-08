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

      @choices = []
      chat_attributes[ :choices ]&.each do | json_choice |
        @choices.push( ChatResultChoice.new( json_choice ) )
      end
      @metrics = ChatMetrics.new( chat_attributes[ :metrics ] ) \
        if chat_attributes.key?( :metrics )
    end

    def message 
      return nil if @choices.empty?
      @choices.first.message
    end

    def text 
      return self.message&.text || ''
    end

  end

end
