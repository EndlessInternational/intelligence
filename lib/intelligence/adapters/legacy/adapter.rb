require_relative '../generic/adapter'
require_relative 'chat_methods'

module Intelligence
  module Legacy 
    class Adapter < Generic::Adapter
      include ChatMethods
    end
  end
end

