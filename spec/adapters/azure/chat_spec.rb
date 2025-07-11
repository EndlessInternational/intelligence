require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :azure ]} chat requests", :azure do

  include_context 'vcr'

  before do
    raise "An AZURE_API_KEY must be defined in the environment." unless ENV[ 'AZURE_API_KEY' ]
    raise "An AZURE_BASE_URI must be defined in the environment." unless ENV[ 'AZURE_BASE_URI' ]
  end

  # this is needed for azure test to avoid the rate limit
  after( :each ) do | example |
    cassette = VCR.current_cassette
    sleep 1 if cassette && cassette.new_recorded_interactions.any? 
  end

  let( :adapter ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            128 
        temperature           0
      end
    end
  end

  let( :adapter_with_tool ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
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
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            24 
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            24
        temperature           0
        stop                  'five'
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :azure ].build! do   
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'gpt-4.1'
        max_tokens            32
        temperature           0
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :azure ].build! do 
      key                     'invalid key'
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'pixtral-12b-2409'        
        max_tokens            16
        temperature           0
      end
    end
  end 

  let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :azure ].build! do 
      key                     ENV[ 'AZURE_API_KEY' ]
      base_uri                ENV[ 'AZURE_BASE_URI' ]
      chat_options do
        model                 'invalid'
        max_tokens            16
        temperature           0
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded', adapter: :adapter_with_limited_max_tokens
  include_examples 'chat requests with stop sequence', adapter: :adapter_with_stop_sequence 
  include_examples 'chat requests without alternating roles'

  include_examples 'chat requests with binary encoded images', adapter: :vision_adapter
  include_examples 'chat requests with file images', adapter: :vision_adapter

  include_examples 'chat requests with tools'
  include_examples 'chat requests with adapter tools'
  include_examples 'chat requests with complex tools'
  include_examples 'chat requests with parallel tools'
  include_examples 'chat requests with tools multiturn'

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model', error_type: 'invalid_request_error'
end
