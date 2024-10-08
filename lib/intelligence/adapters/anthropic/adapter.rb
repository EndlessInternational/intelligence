require_relative 'chat_methods'

module Intelligence
  module Anthropic
    class Adapter < Adapter::Base

      configuration do 

        # normalized properties for all endpoints
        parameter :key, required: true 

        # anthropic specific properties for all endpoints
        parameter :version, String, required: true, default: '2023-06-01'
 
        group :chat_options do 
  
          # normalized properties for anthropic generative text endpoint
          parameter :model, String, required: true
          parameter :max_tokens, Integer, required: true
          parameter :temperature, Float
          parameter :top_k, Integer
          parameter :top_p, Float
          parameter :stop, String, array: true, as: :stop_sequences
          parameter :stream, [ TrueClass, FalseClass ]

          # anthropic variant of normalized properties for anthropic generative text endpoints
          parameter :stop_sequences, String, array: true

          # anthropic specific properties for anthropic generative text endpoints
          parameter :tool_choice do 
            parameter :type, String  
            # the name parameter should only be set if type = 'tool'
            parameter :name, String
          end
          group :metadata do
            parameter :user_id, String
          end 
          
        end
        
      end

      attr_reader :key
      attr_reader :version
      attr_reader :chat_options

      def initialize( attributes = nil, &block )
        configuration = self.class.configure( attributes, &block ) 
        @key = configuration[ :key ]
        @version = configuration[ :version ]
        @chat_options = configuration[ :chat_options ] || {}
      end

      include ChatMethods

    end 
  end
end

