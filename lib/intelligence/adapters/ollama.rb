require_relative 'generic/adapter'

module Intelligence
  module Ollama

    class Adapter < Generic::Adapter
      
      DEFAULT_BASE_URI        = 'http://localhost:11435/v1'

      schema do 
        
        base_uri              String, default: DEFAULT_BASE_URI
        key                   String 

        chat_options do 
          max_tokens          Integer
          model               String
          stop                String, array: true
          stream              [ TrueClass, FalseClass ]
          temperature         Float
        end

      end

    end

  end
end
