require_relative '../../adapter'
require_relative 'chat_request_methods'
require_relative 'chat_response_methods'

module Intelligence
  module Generic
    class Adapter < Adapter::Base
      include ChatRequestMethods
      include ChatResponseMethods
    end 
  end
end
