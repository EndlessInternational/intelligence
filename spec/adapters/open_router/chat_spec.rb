require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :open_router ]} chat requests", :open_router do

  include_context 'vcr'

  before do
    raise "A OPENROUTER_API_KEY must be defined in the environment." unless ENV[ 'OPENROUTER_API_KEY' ]
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :open_router ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'meta-llama/llama-3.2-11b-vision-instruct'
        max_tokens            16
        temperature           0
      end;
    end
  end

  let( :adapter ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'meta-llama/llama-3.2-11b-vision-instruct'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'meta-llama/llama-3.2-11b-vision-instruct'
        max_tokens            24
        temperature           0
        stop                  'five'
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
        provider do 
          order               [ 'Hyperbolic' ]
          allow_fallbacks     false 
        end
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence'
  include_examples 'chat requests with error response'
  include_examples 'chat requests with binary encoded images',
                   adapter: :vision_adapter
  include_examples 'chat requests without alternating roles'

end
