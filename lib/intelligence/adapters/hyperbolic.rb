require_relative 'generic/adapter'

module Intelligence
  module Hyperbolic

    class Adapter < Generic::Adapter

      chat_request_uri "https://api.hyperbolic.xyz/v1/chat/completions"
      
      schema do 
        key                 String 
        chat_options do 
          model             String
          temperature       Float
          top_p             Float
          n                 Integer
          max_tokens        Integer
          stop              String, array: true
          stream            [ TrueClass, FalseClass ]
          frequency_penalty Float
          presence_penalty  Float
          user              String
        end
      end

    end

  end
end
