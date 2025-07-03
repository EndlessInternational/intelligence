module Intelligence   
  module MessageContent 

    class WebReference < Base
        
      schema do 
        uri             URI
        title           String
        summary         String
        access_date     Date
      end

      attr_reader :uri, :title, :summary, :access_date
      
      def valid?
        @uri && !@uri.empty? 
      end

      def merge( other )   
        self.class.new(
          uri:         other.uri         || uri,
          title:       other.title       || title,
          summary:     other.summary     || summary,
          access_date: other.access_date || access_date
        )
      end

      def to_h
        { 
          type: :web_reference, 
          uri: @uri, title: @title, summary: @summary, access_date: @access_date 
        }
      end

    end 

  end
end
