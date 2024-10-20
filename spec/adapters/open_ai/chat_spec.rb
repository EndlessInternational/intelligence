require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :open_ai ]} chat requests", :open_ai do

  include_context 'vcr'

  before do 
    raise "An OPENAI_API_KEY must be defined in the environment." unless ENV[ 'OPENAI_API_KEY' ]
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :open_ai ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'gpt-4o'
        max_tokens            16
      end
    end
  end

  let( :adapter ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        temperature           0
        max_tokens            24
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key   ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        max_tokens            24
        temperature           0
        stop                  'five'
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence'
  include_examples 'chat requests with error response'
  include_examples 'chat requests with binary encoded images'
  include_examples 'chat requests with file images'
  include_examples 'chat requests without alternating roles'

end
