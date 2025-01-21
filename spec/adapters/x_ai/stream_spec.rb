require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :x_ai ]} stream requests", :x_ai do

  include_context 'vcr'

  before do 
    raise "An XAI_API_KEY must be defined in the environment." unless ENV[ 'XAI_API_KEY' ]
  end

  # this is needed for x-AI test to avoid the rate limit
  after( :each ) do | example |
    cassette = VCR.current_cassette
    sleep 1 if cassette && cassette.new_recorded_interactions.any? 
  end

  let( :adapter ) do
    Intelligence::Adapter[ :x_ai ].build! do   
      key                     ENV[ 'XAI_API_KEY' ]
      chat_options do
        model                 'grok-beta'
        max_tokens            128
        temperature           0

        stream                true
      end
    end
  end 

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :x_ai ].build! do   
      key                     ENV[ 'XAI_API_KEY' ]
      chat_options do
        model                 'grok-beta'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end


  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :x_ai ].build! do   
      key                     ENV[ 'XAI_API_KEY' ]
      chat_options do
        model                 'grok-beta'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :x_ai ].build! do   
      key                     ENV[ 'XAI_API_KEY' ]
      chat_options do
        model                 'grok-beta'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end


  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded',
                   adapter: :adapter_with_limited_max_tokens
  # include_examples 'stream requests with stop sequence', 
  #                 adapter: :adapter_with_stop_sequence
  include_examples 'stream requests without alternating roles'
  # include_examples 'stream requests with binary encoded images', 
  #                 adapter: :vision_adapter

  include_examples 'stream requests with tools'
  # include_examples 'stream requests with parallel tools'

end
