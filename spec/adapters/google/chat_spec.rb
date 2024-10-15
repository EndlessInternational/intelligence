require 'spec_helper'

RSpec.describe Intelligence::Adapter[ :google ], :google do

  include_context 'vcr'

  before do
    raise "An GOOGLE_API_KEY must be defined in the environment." unless ENV[ 'GOOGLE_API_KEY' ]
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :google ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'gemini-1.5-pro-002'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key   ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-1.5-pro-002'
        max_tokens            16
        temperature           0
      end
    end
  end
  
  let( :vision_adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key   ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-1.5-pro-002'
        max_tokens            32 
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :google ].build! do   
      key   ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-1.5-pro-002'
        max_tokens            16
        temperature           0
        stop                  'five'
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key   ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-1.5-pro-002'
        max_tokens            16
        temperature           0
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence'
  include_examples 'chat requests with error response'
  include_examples 'chat requests with binary images'
  include_examples 'chat requests without alternating roles'

end
  
