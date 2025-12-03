module Intelligence

  #
  # The ChatRequestMethods module extends a Faraday request, adding the +receive_result+ method. 
  #
  module ChatRequestMethods

    def receive_result( &block )
       @_intelligence_result_callback = block
    end 

  end

  #
  # The ChatResponseMethods module extends a Faraday reponse, adding the +result+ method. 
  #
  module ChatResponseMethods

    def result
      @_intelligence_result
    end 

  end

  ##
  # The +ChatRequest+ class encapsulates a request to an LLM. After creating a new +ChatRequest+ 
  # instance you can make the actual request by calling the +chat+ or +stream+ methods. In order
  # to construct a +ChatRequest+ you must first construct and configure an adapter.
  #
  # === example
  # 
  # adapter = Intelligence::Adapter.build( :open_ai ) do 
  #   key ENV[ 'OPENAI_API_KEY' ]
  #   chat_options do 
  #     model 'gpt-4o'
  #     max_tokens 512
  #   end 
  # end 
  #
  # request = Intelligence::ChatRequest.new( adapter: adapter )
  # response = request.chat( 'Hello!' )
  #
  # if response.success?
  #   puts response.result.text 
  # else 
  #   puts response.result.error_description 
  # end 
  # 
  class ChatRequest 

    DEFAULT_CONNECTION = Faraday.new { | builder | builder.adapter Faraday.default_adapter }

    ##
    # The +initialize+ method initializes the +ChatRequest+ instance. You MUST pass a previously 
    # constructed and configured +adapter+ and optionally a (Faraday) +connection+.
    #
    def initialize( connection: nil, adapter: , **options )
      @connection = connection || DEFAULT_CONNECTION
      @adapter = adapter
      @options = options || {}

      raise ArgumentError.new( 'An adapter must be configured before a request is constructed.' ) \
        if @adapter.nil?
    end

    ## 
    # The +chat+ method leverages the adapter associated with this +ChatRequest+ instance to 
    # construct and make an HTTP request - through Faraday - to an LLM service. The +chat+ method 
    # always returns a +Faraday::Respose+ which is augmented with a +result+ method. 
    #
    # If the response is successful ( if +response.success?+ returns true ) the +result+ method 
    # returns a +ChatResponse+ instance. If the response is not successful a +ChatErrorResult+ 
    # instance is returned.
    #
    # === arguments 
    # * +conversation+ - an instance of +Intelligence::Conversation+ or String; this encapsulates 
    #                    the content to be sent to the LLM
    # * +options+      - one or more Hashes with options; these options overide any of the 
    #                    configuration options used to configure the adapter; you can, for 
    #                    example, pass +{ chat_options: { max_tokens: 1024 }+ to limit the 
    #                    response to 1024 tokens.
    def chat( conversation, *options )

      conversation = build_quick_conversation( conversation ) if conversation.is_a?( String )
      options = options.compact.reduce( {} ) { | accumulator, o | accumulator.merge( o ) }
      options = @options.merge( options )

      # conversation and tools are presented as simple Hashes to the adapter
      conversation = conversation.to_h
      options[ :tools ] = options[ :tools ].to_a.map!( &:to_h ) if options[ :tools ]

      uri = @adapter.chat_request_uri( options )
      headers = @adapter.chat_request_headers( options )
      payload = @adapter.chat_request_body( conversation, options )

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

    def stream( conversation, *options )

      conversation = build_quick_conversation( conversation ) if conversation.is_a?( String )
      options = options.compact.reduce( {} ) { | accumulator, o | accumulator.merge( o ) }
      options = @options.merge( options )
      
      # conversation and tools are presented as simple Hashes to the adapter
      conversation = conversation.to_h
      options[ :tools ] = options[ :tools ].to_a.map!( &:to_h ) if options[ :tools ]

      uri = @adapter.chat_request_uri( options )
      headers = @adapter.chat_request_headers( options )
      payload = @adapter.chat_request_body( conversation, options )

      context = nil
      response = @connection.post( uri ) do | request |

        headers.each { | key, value | request.headers[ key ] = value }
        request.body = payload
        yield request.extend( ChatRequestMethods ) 

        result_callback = request.instance_variable_get( "@_intelligence_result_callback" )
        request.options.on_data = Proc.new do | chunk, received_bytes |
          context, attributes = @adapter.stream_result_chunk_attributes( context, chunk )
          result_callback.call( ChatResult.new( attributes ) ) \
            unless result_callback.nil? || attributes.nil?
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

  private 

    def build_quick_conversation( text )
      conversation = Conversation.new() 
      conversation.messages << Message.build! do 
        role :user 
        content text: text 
      end 
      conversation
    end

  end

end
