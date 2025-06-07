require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :together_ai ]} chat requests", :together_ai do

  include_context 'vcr'

  before do
    raise "A TOGETHERAI_API_KEY must be defined in the environment." unless ENV[ 'TOGETHERAI_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Llama-3.3-70B-Instruct-Turbo'
        max_tokens            128 
        temperature           0
      end
    end
  end 

  let( :adapter_with_tool ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Llama-3.3-70B-Instruct-Turbo'
        max_tokens            128 
        temperature           0

        tool do     
          name :get_location 
          description \
            "The get_location tool will return the users city, state or province and country."
        end
      end
    end
  end

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Llama-3.3-70B-Instruct-Turbo'
        max_tokens            24 
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Llama-3.3-70B-Instruct-Turbo'
        max_tokens            24
        temperature           0
        stop                  'five'
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :together_ai ].build! do   
      key                     ENV[ 'TOGETHERAI_API_KEY' ]
      chat_options do
        model                 'meta-llama/Llama-3.2-11B-Vision-Instruct-Turbo'
        max_tokens            24
        temperature           0
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :together_ai ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :together_ai ].build! do 
      key                     ENV[ 'TOGETHERAI_API_KEY' ] 
      chat_options do
        model                 'invalid_model'
        max_tokens            16
        temperature           0
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded', 
                   adapter: :adapter_with_limited_max_tokens 
  include_examples 'chat requests with stop sequence', 
                   adapter: :adapter_with_stop_sequence
  include_examples 'chat requests without alternating roles'
  include_examples 'chat requests with binary encoded images', 
                   adapter: :vision_adapter
  
  # tools no longer work with together ai although they did historically; this may 
  # be a model problem but I cannot find a working model
  # include_examples 'chat requests with tools'
  # include_examples 'chat requests with complex tools'
  # include_examples 'chat requests with parallel tools'

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model'
end
