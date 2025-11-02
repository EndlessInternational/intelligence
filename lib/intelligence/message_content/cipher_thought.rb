module Intelligence   
  module MessageContent 

    class CipherThought < Base
      # note: a cipher thought has no portable payload; only vendor specific
      #       payloads; such as that from openai
      
      def valid?
        true
      end
    end 

  end
end
