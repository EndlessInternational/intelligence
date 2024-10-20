require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :cerebras ]} stream requests", :cerebras do

  include_context 'vcr'

  # this is needed for cerebras test to avoid the rate limit
  after( :each ) do | example |
    sleep 5 if example.metadata[ :record_cassettes ]
  end

  before do 
    raise "An CEREBRAS_API_KEY must be defined in the environment." unless ENV[ 'CEREBRAS_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :cerebras ].build! do   
      key                     ENV[ 'CEREBRAS_API_KEY' ]
      chat_options do
        model                 'llama3.1-70b'
        max_tokens            16

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :cerebras ].build! do   
      key   ENV[ 'CEREBRAS_API_KEY' ]
      chat_options do
        model                 'llama3.1-70b'
        max_tokens            24
        stop                  'five'

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence', adapter: :adapter_with_stop_sequence  
  include_examples 'stream requests without alternating roles'

end
