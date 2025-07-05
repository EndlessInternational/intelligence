require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :open_ai ]} chat requests", :open_ai do

  include_context 'vcr'

  before do 
    raise "An OPENAI_API_KEY must be defined in the environment." unless ENV[ 'OPENAI_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        temperature           0
        max_tokens            128
      end
    end
  end

  let( :adapter_with_tool ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        temperature           0
        max_tokens            128

        tool do     
          name :get_location 
          description \
            "The get_location tool will return the users city, state or province and country."
        end
      end
    end
  end

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        temperature           0
        max_tokens            16
      end
    end
  end

  let( :adapter_with_web_search ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        temperature           0
        max_tokens            1024
        abilities do 
          web_search 
        end
      end
    end
  end

  let( :adapter_with_thought ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'o3'
        max_tokens            4096
        reasoning do 
          effort              :high
          summary             :detailed
        end
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :open_ai ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'gpt-4o'
        max_tokens            16
      end
    end
  end

  let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :open_ai ].build! do 
      key                     ENV[ 'OPENAI_API_KEY' ] 
      chat_options do
        model                 'invalid_model'
        max_tokens            16
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded',
                   adapter: :adapter_with_limited_max_tokens
  include_examples 'chat requests with binary encoded images'
  include_examples 'chat requests with file images'
  include_examples 'chat requests without alternating roles'
  include_examples 'chat requests with thought', 
                   adapter: :adapter_with_thought

  include_examples 'chat requests with tools'
  include_examples 'chat requests with adapter tools'
  include_examples 'chat requests with complex tools'
  include_examples 'chat requests with parallel tools'

  include_examples 'chat requests with web search', 
                   adapter: :adapter_with_web_search

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model', 
                   error_type: 'invalid_request_error'
end
