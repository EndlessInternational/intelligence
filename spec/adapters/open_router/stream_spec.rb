require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :open_router ]} stream requests", :open_router do

  before do 
    raise "An OPENROUTER_API_KEY must be defined in the environment." unless ENV[ 'OPENROUTER_API_KEY' ]
  end

  include_context 'vcr'

  let( :adapter ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'meta-llama/llama-3.2-11b-vision-instruct'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'meta-llama/llama-3.2-11b-vision-instruct'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'qwen/qwen-2-vl-7b-instruct'
        max_tokens            16
        temperature           0

        stream                true
        
        provider do 
          order               [ 'Hyperbolic' ]
          allow_fallbacks     false 
        end
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence'
  include_examples 'stream requests with binary encoded images'
  include_examples 'stream requests without alternating roles'

end
