module Intelligence

  #
  # class. ChatMetrics
  #
  # The ChatMetrics class encapsulates metrics information. These metrics include the number of
  # input tokens consumed, the number of output tokens generated, the total number of tokens,
  # and the duration of the request in milliseconds.
  #
  class ChatMetrics 
  # ---------------
    
    attr_reader   :duration

    attr_reader   :input_tokens
    attr_reader   :cache_read_input_tokens
    attr_reader   :cache_write_input_tokens

    attr_reader   :output_tokens

    def initialize( attributes )
      attributes.each do | key, value |
        instance_variable_set( "@#{key}", value ) if self.respond_to?( "#{key}" )
      end
    end

    def total_tokens
      @total_tokens = @input_tokens + @output_tokens \
        if @total_tokens.nil? && @input_tokens && @output_tokens 
      @total_tokens
    end

    def to_h
      { 
        input_tokens: @input_tokens, 
        output_tokens: @output_tokens,
        cache_read_input_tokens: @cache_read_input_tokens,
        cache_write_input_tokens: @cache_write_input_tokens 
      }.compact
    end
  
  end
end
