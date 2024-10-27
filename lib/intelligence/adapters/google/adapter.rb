require_relative 'chat_request_methods'
require_relative 'chat_response_methods'

module Intelligence
  module Google
    class Adapter < Adapter::Base

      schema do 

        # normalized properties for all endpoints
        key               String  

        chat_options      as: :generationConfig do

          # normalized properties for google generative text endpoint
          model           String
          max_tokens      Integer,    as: :maxOutputTokens
          n               Integer,    as: :candidateCount
          temperature     Float
          top_k           Integer,    as: :topK
          top_p           Float,      as: :topP
          seed            Integer
          stop            String,     array: true, as: :stopSequences
          stream          [ TrueClass, FalseClass ]

          frequency_penalty Float,    as: :frequencyPenalty
          presence_penalty Float,     as: :presencePenalty

          # google variant of normalized properties for google generative text endpoints
          candidate_count Integer,    as: :candidateCount
          max_output_tokens Integer,  as: :maxOutputTokens
          stop_sequences String,      array: true, as: :stopSequences

          # google specific properties for google generative text endpoints
          response_mime_type String,  as: :responseMimeType
          response_schema             as: :responseSchema

          # google specific tool configuration
          tool_configuration          as: :tool_config do
            function_calling          as: :function_calling_config do 
              mode                    Symbol, in: [ :auto, :any, :none ]
              allowed_function_names  String, array: true 
            end
          end 


        end

      end

      include ChatRequestMethods 
      include ChatResponseMethods

    end 

  end

end
