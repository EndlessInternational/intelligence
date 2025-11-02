module Intelligence   
  module MessageContent 

    class Text < Base
      schema do 
        text            String, required: true
      end

      attribute         :text 
      
      def valid?
        ( text || false ) && text.respond_to?( :empty? ) && !text.empty? 
      end
    end 

  end
end