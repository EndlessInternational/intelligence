require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :hyperbolic ]} stream requests", :hyperbolic do

  before do 
    raise "An HYPERBOLIC_API_KEY must be defined in the environment." unless ENV[ 'HYPERBOLIC_API_KEY' ]
  end

  include_context 'vcr'

  let( :adapter ) do
    Intelligence::Adapter[ :hyperbolic ].build! do   
      key                     ENV[ 'HYPERBOLIC_API_KEY' ]
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :hyperbolic ].build! do   
      key   ENV[ 'HYPERBOLIC_API_KEY' ]
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :hyperbolic ].build! do   
      key                     ENV[ 'HYPERBOLIC_API_KEY' ]
      chat_options do
        model                 'Qwen/Qwen2-VL-7B-Instruct'
        max_tokens            24
        temperature           0

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence'
  include_examples 'stream requests with binary encoded images'
  include_examples 'stream requests without alternating roles'

end
