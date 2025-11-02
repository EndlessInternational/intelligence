module Intelligence   
  module MessageContent 

    class Thought < Base
      schema do 
        text            String, required: true
      end

      attribute         :text
      
      def valid?
        true 
      end
    end 

  end
end
