module Intelligence   
  module MessageContent 
    class WebSearchCall < Base
        
      schema do 
        status          Symbol, in: [ :searching, :complete ]
        query           String
      end

      attribute         :status, :query 
      
      def valid?
        true 
      end

      def complete?
        @status.to_s == 'complete'
      end

    end 
  end
end
