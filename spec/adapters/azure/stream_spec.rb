require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :azure ]} stream requests", :azure do

  include_context 'vcr'  

  before do 
    raise "An AZURE_API_KEY must be defined in the environment." unless ENV[ 'AZURE_API_KEY' ]
    raise "An AZURE_BASE_URI must be defined in the environment." unless ENV[ 'AZURE_BASE_URI' ]
  end

  # this is needed for azure test to avoid the rate limit
  after( :each ) do | example |
    cassette = VCR.current_cassette
    sleep 2 if !cassette || 
               cassette && cassette.new_recorded_interactions.any? 

  end

  let( :adapter ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            128
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            32 
        temperature           0

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests without alternating roles'
  include_examples 'stream requests with token limit exceeded',
                   adapter: :adapter_with_limited_max_tokens
  include_examples 'stream requests with stop sequence',
                   adapter: :adapter_with_stop_sequence  

  include_examples 'stream requests with binary encoded images',
                   adapter: :vision_adapter
  include_examples 'stream requests with file images',
                   adapter: :vision_adapter

  include_examples 'stream requests with tools'
  include_examples 'stream requests with parallel tools'
  include_examples 'stream requests with tools multiturn'

end
