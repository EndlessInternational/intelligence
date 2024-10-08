module Intelligence

  #
  # module. ChatRequestMethods
  #
  # The ChatRequestMethods module extends a Faraday request, adding the +receive_result+ method. 
  #
  module ChatRequestMethods

    def receive_result( &block )
       @_intelligence_result_callback = block
    end 

  end

  #
  # module. ChatResponseMethods
  #
  # The ChatResponseMethods module extends a Farada reponse, adding the +result+  method. 
  #
  module ChatResponseMethods

    def result
      @_intelligence_result
    end 

  end

  #
  # class. ChatRequest
  #
  class ChatRequest 

    DEFAULT_CONNECTION = Faraday.new { | builder | builder.adapter Faraday.default_adapter }

    def initialize( connection: nil, adapter: , **options )
      @connection = connection || DEFAULT_CONNECTION
      @adapter = adapter
      @options = options || {}

      raise ArgumentError.new( 'An adapter must be configured before a request is constructed.' ) \
        if @adapter.nil?
    end

    def chat( conversation, options = {} )

      options = @options.merge( options )

      uri = @adapter.chat_request_uri( options )
      headers = @adapter.chat_request_headers( @options.merge( options ) )
      payload = @adapter.chat_request_body( 
        conversation.to_h, 
        options 
      )

      result_callback = nil 
      response = @connection.post( uri ) do | request |
        headers.each { | key, value | request.headers[ key ] = value }
        request.body = payload          
        yield request.extend( ChatRequestMethods ) if block_given?
        result_callback = request.instance_variable_get( "@_intelligence_result_callback" )
      end

      result = nil 
      if response.success?  
        chat_result_attributes = @adapter.chat_result_attributes( response )
        result = ChatResult.new( chat_result_attributes )
      else 
        error_result_attributes = @adapter.chat_result_error_attributes( response )
        result = ChatErrorResult.new( error_result_attributes )
      end
      
      response.instance_variable_set( "@_intelligence_result", result )
      response.extend( ChatResponseMethods ) 
    
    end

    def stream( conversation, options = {} )

      options = @options.merge( options )

      uri = @adapter.chat_request_uri( options )
      headers = @adapter.chat_request_headers( @options.merge( options ) )
      payload = @adapter.chat_request_body( conversation.to_h, options )

      context = nil
      response = @connection.post( uri ) do | request |

        headers.each { | key, value | request.headers[ key ] = value }
        request.body = payload
        yield request.extend( ChatRequestMethods ) 

        result_callback = request.instance_variable_get( "@_intelligence_result_callback" )
        request.options.on_data = Proc.new do | chunk, received_bytes |
          context, attributes = @adapter.stream_result_chunk_attributes( context, chunk )
          result_callback.call( ChatResult.new( attributes ) ) unless attributes.nil?
        end 

      end

      result = nil 
      if response.success?  
        stream_result_attributes = @adapter.stream_result_attributes( context )
        result = ChatResult.new( stream_result_attributes )
      else 
        error_result_attributes = @adapter.stream_result_error_attributes( response )
        result = ChatErrorResult.new( error_result_attributes )
      end
      
      response.instance_variable_set( "@_intelligence_result", result )
      response.extend( ChatResponseMethods )
    
    end

  end

end