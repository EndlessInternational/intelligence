require_relative 'chat_request_methods'
require_relative 'chat_response_methods'

module Intelligence
  module OpenAi
    class Adapter < Adapter::Base

      DEFAULT_BASE_URI              = 'https://api.openai.com/v1'

      schema do 

        # normalized properties, used by all endpoints
        base_uri                    String, default: DEFAULT_BASE_URI
        key                         String
        
        # openai properties, used by all endpoints 
        organization                String 
        project                     String 
        
        chat_options do 
        
          model                     String, requried: true 
          background                [ TrueClass, FalseClass ]
          include                   String, 
                                    array: true,
                                    in: [ 
                                      'file_search_call.results',
                                      'message.input_image.image_url',
                                      'computer_call_output.output.image_url',
                                      'reasoning.encrypted_content',
                                      'code_interpreter_call.outputs'
                                    ]

          instructions              String
          max_tokens                Integer, as: :max_output_tokens
          metadata                  Hash
          previous_response_id      String
          prompt do 
            id                      String
            variables               Hash 
            version                 String
          end
          reasoning do 
            effort                  Symbol, in: [ :low, :medium, :high ]
            summary                 Symbol, in: [ :auto, :concise, :detailed ]
          end
          service_tier              Symbol, in: [ :auto, :default, :flex ]
          store                     [ TrueClass, FalseClass ] 
          stream                    [ TrueClass, FalseClass ] 
          temperature               Float, in: 0..2
          text do 
            format                  Symbol, in: [ :text, :json_schema ]
            # these fields only apply when format is json_schema
            json_schema             do 
              name                  String
              schema                required: true
              description           String
              strict                [ TrueClass, FalseClass ]
            end  
          end
          top_p                     Float
          truncation                Symbol, in: [ :auto, :disabled ]
          user                      String

          max_tool_calls            Integer, in: (1..)
          parallel_tool_calls       [ TrueClass, FalseClass ]
          tool_choice               arguments: :type do 
            type                    Symbol, in: [ :none, :auto, :required ]
            function                arguments: :name do 
              name                  Symbol 
            end 
          end 
          tool                      array: true, as: :tools, &Tool.schema 

          # build in open ai tools
          abilities do 

            image_generation do 
              type                  String, default: 'image_generation'
              background            in: [ :transparent, :opaque, :auto ]
              model                 String
              moderation            String
              output_compression    Integer
              output_format         Symbol, in: [ :png, :webp, :jpeg ]
              partial_images        Integer
              quality               Symbol, in: [ :auto, :low, :medium, :high ]
              size                  String, in: [ 'auto', '1024x1024', '1024x1536', '1536x1024' ]
            end

            local_shell do
              type                  String, default: 'local_shell'
            end 

            code_interpreter do 
              container_id          String
              container do  
                type                String, default: 'auto'
                file_ids            String, array: true
              end
            end

            web_search do 
              type                  String, default: 'web_search_preview'
              search_context_size   Symbol, in: [ :low, :medium, :high ] 
              user_location do 
                type                Symbol, default: :approximate
                city                String
                country             String 
                region              String
                timezone            String 
              end
            end

            computer_use do 
              type                  default: 'computer_use_preview'
              display_height        Integer, requried: true 
              display_width         Integer, requried: true 
            end
          
          end

          # openai variant of normalized properties for openai generative text endpoints
          max_output_tokens         Integer
          
        end

      end

      include ChatRequestMethods 
      include ChatResponseMethods

    end 
  end
end
