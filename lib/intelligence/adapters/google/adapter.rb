require_relative 'chat_methods'

module Intelligence
  module Google
    class Adapter < Adapter::Base

      configuration do 

        # normalized properties for all endpoints
        parameter :key, String  

        group :chat_options, as: :generationConfig do

          # normalized properties for google generative text endpoint
          parameter :model, String
          parameter :max_tokens, Integer, as: :maxOutputTokens
          parameter :n, Integer, as: :candidateCount
          parameter :temperature, Float
          parameter :top_k, Integer, as: :topK
          parameter :top_p, Float, as: :topP
          parameter :seed, Integer
          parameter :stop, String, array: true, as: :stopSequences
          parameter :stream, [ TrueClass, FalseClass ]

          parameter :frequency_penalty, Float, as: :frequencyPenalty
          parameter :presence_penalty, Float, as: :presencePenalty

          # google variant of normalized properties for google generative text endpoints
          parameter :candidate_count, Integer, as: :candidateCount
          parameter :max_output_tokens, Integer, as: :maxOutputTokens
          parameter :stop_sequences, String, array: true, as: :stopSequences

          # google specific properties for google generative text endpoints
          parameter :response_mime_type, String, as: :responseMimeType
          parameter :response_schema, as: :responseSchema

        end

      end

      include ChatMethods

    end 

  end

end
