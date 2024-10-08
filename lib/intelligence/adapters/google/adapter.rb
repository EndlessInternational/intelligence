require_relative 'chat_methods'

module Intelligence
  module Google
    class Adapter < Adapter::Base

      configuration do 

        # normalized properties for all endpoints
        parameter :key, String, required: true  

        group :chat_options, as: :generationConfig do

          # normalized properties for google generative text endpoint
          parameter :model, String, required: true
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

      attr_reader :key
      attr_reader :model
      attr_reader :stream
      attr_reader :chat_options

      def initialize( attributes = nil, &block )
        configuration = self.class.configure( attributes, &block ).to_h 
        @key = configuration.delete( :key )
        @model = configuration[ :generationConfig ]&.delete( :model )
        @stream = configuration[ :generationConfig ]&.delete( :stream ) || false
        @chat_options = configuration[ :generationConfig ] || {}
      end

      include ChatMethods

    end 

  end

end
