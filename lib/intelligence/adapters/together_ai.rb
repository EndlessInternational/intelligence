require_relative 'legacy/adapter'

module Intelligence
  module TogetherAi

    class Adapter < Legacy::Adapter

      chat_request_uri "https://api.together.xyz/v1/chat/completions"
      
      configuration do 
        parameter :key, String 
        group :chat_options do 
          parameter :model, String
          parameter :temperature, Float
          parameter :top_p, Float
          parameter :top_k, Integer
          parameter :n, Integer
          parameter :max_tokens, Float
          parameter :stop, String, array: true
          parameter :stream, [ TrueClass, FalseClass ]
          parameter :frequency_penalty, Float
          parameter :presence_penalty, Float
          parameter :repetition_penalty, Float
          parameter :user, String
        end
      end

      def translate_end_result( end_result )
        case end_result
          when 'eos'
            :ended
          when 'length'
            :token_limit_exceeded
          when 'stop'
            :end_sequence_encountered
          when 'function_call'
            :tool_called
          else
            nil
        end
      end

    end

  end
end