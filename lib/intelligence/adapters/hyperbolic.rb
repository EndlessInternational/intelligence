require_relative 'generic/adapter'

module Intelligence
  module Hyperbolic

    class Adapter < Generic::Adapter

      DEFAULT_BASE_URI = 'https://api.hyperbolic.xyz/v1'
      
      schema do 
        base_uri            String,         default: DEFAULT_BASE_URI
        key                 String 
        chat_options do 
          model             String
          temperature       Float
          top_p             Float
          n                 Integer
          max_tokens        Integer
          stop              String,         array: true
          stream            [ TrueClass, FalseClass ]
          frequency_penalty Float
          presence_penalty  Float
          user              String
        end
      end

    end

  end
end
