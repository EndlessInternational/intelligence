module Intelligence   
  module MessageContent 

    class File < Base
  
      schema do 
        content_type    String  
        uri             URI, required: true 
      end

      attribute         :uri

      def initialize( attributes = nil )
        if attributes&.fetch( :uri )
          attributes = attributes.dup
          attributes[ :uri ] = URI( attributes[ :uri ] ) unless attributes[ :uri ].is_a?( URI )
        end
        super( attributes )
      end

      def content_type 
        @attributes[ :content_type ] ||= begin
          computed = valid_uri? ? MIME::Types.type_for( uri.path )&.first&.content_type : nil
          computed&.freeze
        end
      end

      def valid_uri?( schemes = [ 'http', 'https' ] )
        !!( uri && schemes.include?( uri.scheme ) && uri.path && !uri.path.empty? )      
      end

      def valid?
        valid_uri? && !MIME::Types[ content_type ].empty?
      end

      def to_h
        hash = super
        hash[ :uri ] = uri.to_s if hash[ :uri ]
        hash[ :content_type ] = content_type
        hash
      end

    end 

  end
end