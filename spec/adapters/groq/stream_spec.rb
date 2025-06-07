require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :groq ]} stream requests", :groq do

  include_context 'vcr'

  before do 
    raise "An GROQ_API_KEY must be defined in the environment." unless ENV[ 'GROQ_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :groq ].build! do   
      key                     ENV[ 'GROQ_API_KEY' ]
      chat_options do
        model                 'mistral-saba-24b'
        max_tokens            24
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :groq ].build! do   
      key   ENV[ 'GROQ_API_KEY' ]
      chat_options do
        model                 'mistral-saba-24b'
        max_tokens            64 
        stop                  'five'
        temperature           0

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence', adapter: :adapter_with_stop_sequence  
  include_examples 'stream requests without alternating roles'

end
