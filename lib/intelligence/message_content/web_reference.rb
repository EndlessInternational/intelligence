module Intelligence   
  module MessageContent 
    class WebReference < Base
        
      schema do 
        uri             URI
        title           String
        summary         String
        access_date     Date
      end

      attribute         :uri, :title, :summary, :access_date
      
      def valid?
        @uri && !@uri.empty? 
      end

    end 
  end
end
