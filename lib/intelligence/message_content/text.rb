module Intelligence   
  module MessageContent 

    class Text < Base
      attr_reader :text 
      
      def valid?
        ( text || false ) && text.respond_to?( :empty? ) && !text.empty? 
      end

      def to_h
        { type: :text, text: text }
      end
    end 

  end
end
