require_relative '../../adapter'
require_relative 'chat_methods'

module Intelligence
  module Generic
    class Adapter < Adapter::Base

      attr_reader :key
      attr_reader :chat_options

      def initialize( attributes = nil, &block )
        configuration = self.class.configure( attributes, &block ) 
        @key = configuration[ :key ]
        @chat_options = configuration[ :chat_options ] || {}
      end

      include ChatMethods
    
    end 
  end
end