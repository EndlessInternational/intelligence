require_relative 'generic/adapter'

module Intelligence
  module Cerebras

    class Adapter < Generic::Adapter

      DEFAULT_BASE_URI    = 'https://api.cerebras.ai/v1'
      
      schema do 
        
        base_uri          String, default: DEFAULT_BASE_URI
        key               String 

        chat_options do 
          model           String
          max_tokens      Integer
          response_format do 
            type          String, default: 'json_schema'
            json_schema
          end
          seed            Integer
          stop            array: true
          stream          [ TrueClass, FalseClass ]
          temperature     Float
          top_p           Float
          tool            array: true, as: :tools, &Tool.schema 
          tool_choice do 
            type          String 
            mame          String
          end
          user            String
        end
        
      end

    end

  end
end
