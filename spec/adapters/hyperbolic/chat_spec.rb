require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :hyperbolic ]} chat requests", :hyperbolic do

  include_context 'vcr'

  before do
    raise "A HYPERBOLIC_API_KEY must be defined in the environment." unless ENV[ 'HYPERBOLIC_API_KEY' ]
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :hyperbolic ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter ) do
    Intelligence::Adapter[ :hyperbolic ].build! do   
      key   ENV[ 'HYPERBOLIC_API_KEY' ]
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :hyperbolic ].build! do   
      key   ENV[ 'HYPERBOLIC_API_KEY' ]
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct'
        max_tokens            24
        temperature           0
        stop                  'five'
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :hyperbolic ].build! do   
      key   ENV[ 'HYPERBOLIC_API_KEY' ]
      chat_options do
        model                 'Qwen/Qwen2-VL-7B-Instruct'
        max_tokens            32
        temperature           0
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence'
  include_examples 'chat requests with error response'
  include_examples 'chat requests with binary images'
  include_examples 'chat requests without alternating roles'

end
