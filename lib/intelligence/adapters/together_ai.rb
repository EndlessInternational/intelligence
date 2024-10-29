require_relative 'generic/adapter'

module Intelligence
  module TogetherAi

    class Adapter < Generic::Adapter

      chat_request_uri "https://api.together.xyz/v1/chat/completions"
      
      schema do 
        key                       String 
        chat_options do 
          model                   String
          temperature             Float
          top_p                   Float
          top_k                   Integer
          n                       Integer
          max_tokens              Float
          stop                    String, array: true
          stream                  [ TrueClass, FalseClass ]
          frequency_penalty       Float
          presence_penalty        Float
          repetition_penalty      Float
          user                    String
        end
      end

      def translate_end_result( end_result )
        case end_result
          when 'eos', 'stop'
            :ended
          # unfortunatelly eos seems to only work with certain models while others always return
          # stop so for now tomorrow ai will not support :end_sequence_encountered
          # when 'stop'
          #   :end_sequence_encountered
         when 'length'
            :token_limit_exceeded
          when 'tool_calls'
            :tool_called
          else
            nil
        end
      end

    end

  end
end
