module Intelligence   
  module MessageContent 

    class Binary < Base
  
      configuration do 
        parameter :content_type, String, required: true 
        parameter :bytes, String, required: true 
      end

      attr_reader :content_type 
      attr_reader :bytes
      
      def valid?
        ( @content_type || false ) && !MIME::Types[ @content_type ].empty? && 
        ( @bytes || false ) && bytes.respond_to?( :empty? ) && !bytes.empty? 
      end

      def image?
        ( @content_type || false ) && 
        ( MIME::Types[ @content_type ]&.first&.media_type == 'image' )
      end

      def to_h
        { type: :binary, content_type: content_type, bytes: bytes }
      end
    end 

  end
end
