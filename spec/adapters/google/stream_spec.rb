require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :google ]} stream requests", :google do

  include_context 'vcr'
  
  before do 
    raise "An GOOGLE_API_KEY must be defined in the environment." unless ENV[ 'GOOGLE_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            128
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            32
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :google ].build! do   
      key   ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            32
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            32 
        temperature           0

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded', 
                   adapter: :adapter_with_limited_max_tokens
  include_examples 'stream requests with stop sequence', 
                   adapter: :adapter_with_limited_max_tokens  
  include_examples 'stream requests without alternating roles'
  include_examples 'stream requests with binary encoded images'
  include_examples 'stream requests with binary encoded audio'
  include_examples 'stream requests with binary encoded pdf'
  include_examples 'stream requests with binary encoded text'

end
