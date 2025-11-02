module Intelligence   
  module MessageContent 

    class Binary < Base
      schema do 
        content_type    String, required: true 
        bytes           String, required: true 
      end

      attribute         :content_type, :bytes

      def valid?
        ( @content_type || false ) && !MIME::Types[ @content_type ].empty? && 
        ( @bytes || false ) && bytes.respond_to?( :empty? ) && !bytes.empty? 
      end

      def image?
        ( @content_type || false ) && 
        ( MIME::Types[ @content_type ]&.first&.media_type == 'image' )
      end
    end 

  end
end
