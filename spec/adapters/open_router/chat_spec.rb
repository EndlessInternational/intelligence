require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :open_router ]} chat requests", :open_router do

  include_context 'vcr'

  before do
    raise "A OPENROUTER_API_KEY must be defined in the environment." unless ENV[ 'OPENROUTER_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'qwen/qwen-2.5-vl-7b-instruct'
        max_tokens            24 
        temperature           0

        provider do 
          order               [ 'Hyperbolic' ]
          allow_fallbacks     false 
        end
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'qwen/qwen-2.5-vl-7b-instruct'
        max_tokens            24
        temperature           0
        stop                  'five'

        provider do 
          order               [ 'Hyperbolic' ]
          allow_fallbacks     false 
        end
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :open_router ].build! do   
      key                     ENV[ 'OPENROUTER_API_KEY' ]
      chat_options do
        model                 'qwen/qwen-2.5-vl-7b-instruct'
        max_tokens            24
        temperature           0
        provider do 
          order               [ 'Hyperbolic' ]
          allow_fallbacks     false 
        end
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :open_router ].build! do 
      key                     'invalid key'  
      chat_options do
        model                 'qwen/qwen-2.5-vl-7b-instruct'
        max_tokens            16
        temperature           0
      end
    end
  end 

   let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :open_router ].build! do 
      key                     ENV[ 'OPENROUTER_API_KEY' ]  
      chat_options do
        model                 'invalid_model'
        max_tokens            16
        temperature           0
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence', adapter: :adapter_with_stop_sequence  
  include_examples 'chat requests with binary encoded images', adapter: :vision_adapter
  include_examples 'chat requests without alternating roles'

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model', error_type: 'invalid_request_error'
end
