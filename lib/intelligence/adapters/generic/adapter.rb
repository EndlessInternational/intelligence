require_relative '../../adapter'
require_relative 'chat_methods'

module Intelligence
  module Generic
    class Adapter < Adapter::Base
      include ChatMethods
    end 
  end
end
