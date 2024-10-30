module Intelligence   
  module MessageContent 

    class Text < Base
        
      schema do 
        text            String, required: true
      end

      attr_reader :text 
      
      def valid?
        ( text || false ) && text.respond_to?( :empty? ) && !text.empty? 
      end

      def merge( other )
        other_text = other.text
        text = @text 
        text = ( @text || '' ) + other_text if other_text

        self.class.new( text: text )
      end

      def to_h
        { type: :text, text: text }
      end
    end 

  end
end
