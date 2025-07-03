module Intelligence   
  module MessageContent 

    class WebSearchCall < Base
        
      schema do 
        query String
      end

      attr_reader :query 
      
      def valid?
        true 
      end

      def merge( other )
        query = @query  
        query = other.query if other.query
        self.class.new( query: query )
      end

      def to_h
        { type: :web_search_call, query: query }
      end
    end 

  end
end
