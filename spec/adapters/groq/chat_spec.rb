require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :groq ]} chat requests", :groq do

  include_context 'vcr'

  before do
    raise "A GROQ_API_KEY must be defined in the environment." unless ENV[ 'GROQ_API_KEY' ]
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :groq ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'llama-3.1-70b-versatile'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter ) do
    Intelligence::Adapter[ :groq ].build! do   
      key   ENV[ 'GROQ_API_KEY' ]
      chat_options do
        model                 'llama-3.1-70b-versatile'
        max_tokens            16
        temperature           0
      end
    end
  end
  
  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :groq ].build! do   
      key   ENV[ 'GROQ_API_KEY' ]
      chat_options do
        model                 'llama-3.1-70b-versatile'
        max_tokens            32 
        stop                  'five'
        temperature           0
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence'
  include_examples 'chat requests with error response'
  include_examples 'chat requests without alternating roles'

end
