module Intelligence

  class ErrorResult
  # ---------------

    attr_reader :error_type
    attr_reader :error
    attr_reader :error_description

    def initialize( error_attributes )
    # --------------------------------
      error_attributes.each do | key, value |
        instance_variable_set( "@#{key}", value ) if self.respond_to?( "#{key}" )
      end
    end

    def empty?
    # --------
      @error_type.nil? && @error.nil? && @error_description.nil?
    end

  end

end