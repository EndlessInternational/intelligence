module Intelligence
  class Message

    ROLES = [ :system, :user, :assistant ]

    attr_reader :role
    attr_reader :contents

    def initialize( role, content_type = nil, content_attributes = nil )
      raise ArgumentError.new( "The role is invalid. It must be one of #{ROLES.join( ', ' )}." ) \
        unless ROLES.include?( role.to_sym )

      @role = role.to_sym 
      @contents = []   

      @contents << MessageContent.build( content_type, content_attributes ) unless content_type.nil?
    end

    def append_content( content )
      @contents.push( content ) unless content.nil?
      self 
    end

    def build_and_append_content( content_type = nil, content_attributes = nil )
      append_content(
        MessageContent.build( content_type, content_attributes )
      )
      self 
    end

    alias :<< :append_content
   
    def each_content( &block )
      @contents.each( &block )
    end

    def empty?
      @contents.empty?
    end

    def valid?
      !@role.nil? && @contents.all?{ | contents | contents.valid? }
    end

    def to_h
      { 
        role: @role,
        contents: @contents.map { | c | c.to_h }
      }
    end

  end
end
