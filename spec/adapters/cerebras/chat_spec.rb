require 'spec_helper'

RSpec.describe Intelligence::Adapter[ :cerebras ], :cerebras do

  include_context 'vcr'

  # this is needed for cerebras test to avoid the rate limit
  after( :each ) do | example |
    cassette = VCR.current_cassette
    sleep 10 if cassette && cassette.new_recorded_interactions.any? 
  end

  before do
    raise "A CEREBRAS_API_KEY must be defined in the environment." unless ENV[ 'CEREBRAS_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :cerebras ].build! do   
      key                     ENV[ 'CEREBRAS_API_KEY' ]
      chat_options do
        model                 'llama3.1-70b'
        max_tokens            16
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :cerebras ].build! do   
      key                     ENV[ 'CEREBRAS_API_KEY' ]
      chat_options do
        model                 'llama3.1-70b'
        max_tokens            24
        stop                  'five'
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :cerebras ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'llama3.1-70b'
        max_tokens            16
      end
    end
  end

  let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :cerebras ].build! do 
      key                     ENV[ 'CEREBRAS_API_KEY' ]  
      chat_options do
        model                 'invalid model'
        max_tokens            16
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence', adapter: :adapter_with_stop_sequence 
  include_examples 'chat requests without alternating roles'

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model' 
end
