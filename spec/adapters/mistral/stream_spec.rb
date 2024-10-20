require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :mistral ]} stream requests", :mistral do

  include_context 'vcr'  

  before do 
    raise "An MISTRAL_API_KEY must be defined in the environment." unless ENV[ 'MISTRAL_API_KEY' ]
  end

  # this is needed for mistral test to avoid the rate limit
  after( :each ) do | example |
    sleep 2 if example.metadata[ :record_cassettes ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :mistral ].build! do   
      key                     ENV[ 'MISTRAL_API_KEY' ]
      chat_options do
        model                 'mistral-large-latest'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :mistral ].build! do   
      key                     ENV[ 'MISTRAL_API_KEY' ]
      chat_options do
        model                 'mistral-large-latest'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :mistral ].build! do   
      key                     ENV[ 'MISTRAL_API_KEY' ]
      chat_options do
        model                 'pixtral-12b-2409'
        max_tokens            32 
        temperature           0

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence'
  include_examples 'stream requests with binary encoded images',
                   adapter: :vision_adapter
  include_examples 'stream requests with file images',
                   adapter: :vision_adapter
  include_examples 'stream requests without alternating roles'

end
