require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :samba_nova ]} chat requests", :samba_nova do

  include_context 'vcr'

  before do
    raise "A SAMBANOVA_API_KEY must be defined in the environment." unless ENV[ 'SAMBANOVA_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :samba_nova ].build! do   
      key   ENV[ 'SAMBANOVA_API_KEY' ]
      chat_options do
        model                 'Meta-Llama-3.1-70B-Instruct'
        max_tokens            24 
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :samba_nova ].build! do   
      key                     ENV[ 'SAMBANOVA_API_KEY' ]
      chat_options do
        model                 'Meta-Llama-3.1-70B-Instruct'
        max_tokens            24
        temperature           0
        stop                  'five'
      end
    end
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :samba_nova ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0
      end
    end
  end
 
  let( :adapter_with_invalid_model ) do
    Intelligence::Adapter[ :samba_nova ].build! do 
      key                     ENV[ 'SAMBANOVA_API_KEY' ]  
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
  include_examples 'chat requests without alternating roles'

  include_examples 'chat requests with invalid key'
  include_examples 'chat requests with invalid model', error_type: 'invalid_request_error'
end
