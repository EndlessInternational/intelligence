require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :together_ai ]} stream requests", :together_ai do

  include_context 'vcr'

  before do 
    raise "An TOGETHERAI_API_KEY must be defined in the environment." unless ENV[ 'TOGETHERAI_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo'
        max_tokens            128
        temperature           0

        stream                true
      end
    end
  end 

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end


  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key   ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Llama-3.2-11B-Vision-Instruct-Turbo'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end


  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded',
                   adapter: :adapter_with_limited_max_tokens
  include_examples 'stream requests with stop sequence', 
                   adapter: :adapter_with_stop_sequence
  include_examples 'stream requests without alternating roles'
  include_examples 'stream requests with binary encoded images', 
                   adapter: :vision_adapter

  include_examples 'stream requests with tools'
  include_examples 'stream requests with parallel tools'

end
