require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :groq ]} chat requests", :groq do

  include_context 'vcr'

  before do
    raise "A GROQ_API_KEY must be defined in the environment." unless ENV[ 'GROQ_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :groq ].build! do   
      key                     ENV[ 'GROQ_API_KEY' ]
      chat_options do
        model                 'mistral-saba-24b'
        max_tokens            16
        temperature           0
      end
    end
  end
  
  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :groq ].build! do   
      key                     ENV[ 'GROQ_API_KEY' ]
      chat_options do
        model                 'mistral-saba-24b'
        max_tokens            32 
        stop                  'five'
        temperature           0
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
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :groq ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'mistral-saba-24b'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :groq ].build! do 
      key                     ENV[ 'GROQ_API_KEY' ]  
      chat_options do
        model                 'invalid-model'
        max_tokens            16
        temperature           0
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence', adapter: :adapter_with_stop_sequence  
  include_examples 'chat requests without alternating roles'

  include_examples 'chat requests with tools', adapter: :adapter_with_tool  
  include_examples 'chat requests with adapter tools', adapter: :adapter_with_tool 
  include_examples 'chat requests with complex tools', adapter: :adapter_with_tool 
  include_examples 'chat requests with parallel tools', adapter: :adapter_with_tool 
  include_examples 'chat requests with tools multiturn', adapter: :adapter_with_tool 

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model' 
end
