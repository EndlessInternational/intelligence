require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :google ]} chat requests", :google do

  include_context 'vcr'

  before do
    raise "An GOOGLE_API_KEY must be defined in the environment." unless ENV[ 'GOOGLE_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            128 
        temperature           0
      end
    end
  end

  let( :adapter_with_adapter_tool ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
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

  let( :adapter_with_tools ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            1024 
        temperature           0
      end
    end
  end
  
  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            16 
        temperature           0
      end
    end
  end 
  
  let( :vision_adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            32 
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            196
        temperature           0
        stop                  'five'
        thinking do 
          budget              128
        end
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :google ].build! do   
      key                     ENV[ 'GOOGLE_API_KEY' ]
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            32
        temperature           0
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :google ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'gemini-2.5-flash'
        max_tokens            32
        temperature           0
      end
    end
  end 

  let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :google ].build! do 
      key                     ENV[ 'GOOGLE_API_KEY' ]  
      chat_options do
        model                 'invalid-model'
        max_tokens            32
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
  include_examples 'chat requests with binary encoded images'
  include_examples 'chat requests with binary encoded text'
  include_examples 'chat requests with binary encoded pdf'
  include_examples 'chat requests with binary encoded audio'

  include_examples 'chat requests with tools',
                   adapter: :adapter_with_tools
  include_examples 'chat requests with adapter tools',
                   adapter: :adapter_with_adapter_tool
  include_examples 'chat requests with parallel tools',
                   adapter: :adapter_with_tools
  include_examples 'chat requests with complex tools',
                   adapter: :adapter_with_tools
  include_examples 'chat requests with tools multiturn',
                   adapter: :adapter_with_tools

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model' 
end
  
