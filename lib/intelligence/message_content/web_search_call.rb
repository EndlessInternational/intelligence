module Intelligence   
  module MessageContent 

    class WebSearchCall < Base
        
      schema do 
        status Symbol, in: [ :searching, :complete ]
        query String
      end

      attr_reader :status, :query 
      
      def valid?
        true 
      end

      def complete?
        @status.to_s == 'complete'
      end

      def merge( other )
        query = @query  
        query = other.query if other.query
        self.class.new( query: query )
      end

      def to_h
        { type: :web_search_call, id: id, query: query }.compact
      end
    end 

  end
end
