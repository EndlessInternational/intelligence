module Intelligence   
  module MessageContent 

    class Thought < Base
        
      schema do 
        text            String, required: true
        ciphertext      String
      end

      attr_reader :text 
      attr_reader :ciphertext
      
      def valid?
        true 
      end

      def merge( other )
        other_text = other.text
        text = @text 
        text = ( @text || '' ) + other_text if other_text

        self.class.new( text: text )
      end

      def to_h
        { type: :thought, id: id, text: text, ciphertext: ciphertext }.compact
      end
    end 

  end
end
