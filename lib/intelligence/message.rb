module Intelligence
  class Message

    include DynamicSchema::Definable

    ROLES = [ :system, :user, :assistant ]
    schema do
      role              Symbol, required: true 
      content           array: true, as: :contents do 
        type            Symbol, default: :text

        # note: we replicate these schema elements of the individual content types here to 
        # provide more semantic flexibility when building a message; we don't delegate to the 
        # individual content type schemas because, unlike for a specific content type, not all 
        # attributes are required

        # text 
        text            String 
        # binary and file 
        content_type    String
        bytes           String 
        uri             URI
        # tool call and tool result 
        tool_call_id    String 
        tool_name       String 
        tool_parameters [ Hash, String ]
        tool_result     [ Hash, String ]
      end
    end

    attr_reader :role
    attr_reader :contents

    ##
    # The +build!+ class method constructs and returns a new +Message+ instance. The +build!+ 
    # method accepts message +attributes+ and a block, which may be combined when constructing 
    # a +Message+. The +role+ is required, either as an attribute or in the block. If the +role+ 
    # is not present, an exception will be raised.
    # 
    # The block offers the +role+ method, as well as a +content+ method permiting the caller to 
    # set the role and add content respectivelly. 
    #
    # Note that there is no corresponding +build+ method because a +Message+ strictly requires a 
    # +role+. It cannot be constructed without one.
    # 
    # === examples
    #
    # message = Message.build!( role: :user ) 
    #
    # message = Message.build! do 
    #   role :user 
    #   content do 
    #      type :text 
    #      text 'this is a user message'
    #   end 
    # end 
    #
    # message = Message.build!( role: :user ) do 
    #   content text: 'this is a user message'
    # end 
    #
    # message = Message.build!( role: :user ) do 
    #   content text: 'what do you see in this image?'
    #   content type: :binary do
    #     content_type 'image/png'
    #     bytes File.binread( '99_red_balloons.png' )
    #   end
    # end
    #
    def self.build!( attributes = nil, &block )
      attributes = self.builder.build!( attributes, &block )
      self.new( attributes[ :role ], attributes )
    end

    def initialize( role, attributes = nil )
      @role = role&.to_sym 
      @contents = []   

      raise ArgumentError.new( "The role is invalid. It must be one of #{ROLES.join( ', ' )}." ) \
        unless ROLES.include?( @role )

      if attributes && attributes[ :contents ]
        attributes[ :contents ].each do | content |
          @contents << MessageContent.build!( content[ :type ], content )
        end 
      end
    end

    ##
    # The empty? method return true if the message has no content.
    #
    def empty?
      @contents.empty?
    end

    ## 
    # The valid? method returns true if the message has a valid role, has content, and the content 
    # is valid.
    # 
    def valid?
      ROLES.include?( @role ) && !@contents.empty? && @contents.all?{ | contents | contents.valid? }
    end

    ##
    # The text method is a convenience that returns all text content in the message joined with 
    # a newline. Any non-text content is skipped. If there is no text content an empty string is
    # returned.
    #
    def text  
      result = []
      each_content do | content |
        result << content.text if content.is_a?( MessageContent::Text ) && content.text
      end
      result.join( "\n" ) 
    end

    def each_content( &block )
      @contents.each( &block )
    end

    def append_content( content )
      @contents.push( content ) unless content.nil?
      self 
    end

    alias :<< :append_content

    def to_h
      { 
        role: @role,
        contents: @contents.map { | c | c.to_h }
      }
    end

  end
end
