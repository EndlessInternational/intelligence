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

  let( :adapter_with_tool ) do
    Intelligence::Adapter[ :groq ].build! do   
      key                     ENV[ 'GROQ_API_KEY' ]
      chat_options do
        model                 'moonshotai/kimi-k2-instruct'
        max_tokens            256 
        temperature           0

        tool do     
          name :get_location 
          description \
            "The get_location tool will return the users city, state or province and country."
        end

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence', adapter: :adapter_with_stop_sequence  
  include_examples 'stream requests without alternating roles'

  include_examples 'stream requests with tools', adapter: :adapter_with_tool
  include_examples 'stream requests with parallel tools', adapter: :adapter_with_tool
  include_examples 'stream requests with tools multiturn', adapter: :adapter_with_tool

end
