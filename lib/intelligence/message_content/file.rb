module Intelligence   
  module MessageContent 

    class File < Base
  
      schema do 
        content_type    String  
        uri             URI, required: true 
      end

      def initialize( attributes )
        @uri = URI( attributes[ :uri ] ) if attributes[ :uri ]
        @content_type = attributes[ :content_type ]
      end

      def content_type 
        @content_type ||= valid_uri? ? MIME::Types.type_for( @uri.path )&.first&.content_type : nil
      end

      def valid_uri?( schemes = [ 'http', 'https' ] )
        !!( @uri && schemes.include?( @uri.scheme ) && @uri.path && !@uri.path.empty? )      
      end

      def valid?
        valid_uri? && !MIME::Types[ content_type ].empty?
      end

      def to_h
        { type: :file, id: id, content_type: content_type, uri: @uri.to_s }.compact
      end

    end 

  end
end
