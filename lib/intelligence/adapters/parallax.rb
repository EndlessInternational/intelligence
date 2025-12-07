require_relative 'generic/adapter'

module Intelligence
  module Parallax

    class Adapter < Generic::Adapter
      
      DEFAULT_BASE_URI        = 'http://localhost:3000/v1'

      schema do 
        
        base_uri              String, default: DEFAULT_BASE_URI
        key                   String 

        chat_options do 
          max_tokens          Integer
          model               String
          stop                String, array: true
          stream              [ TrueClass, FalseClass ]
          temperature         Float

          template_arguments  as: :chat_template_kwargs do 
            enable_thinking   [ TrueClass, FalseClass ]
          end
        end

      end

    end

  end
end
