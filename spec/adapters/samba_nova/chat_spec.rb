require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :samba_nova ]} chat requests", :samba_nova do

  include_context 'vcr'

  before do
    raise "A SAMBANOVA_API_KEY must be defined in the environment." unless ENV[ 'SAMBANOVA_API_KEY' ]
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

  let( :adapter ) do
    Intelligence::Adapter[ :samba_nova ].build! do   
      key   ENV[ 'SAMBANOVA_API_KEY' ]
      chat_options do
        model                 'Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :samba_nova ].build! do   
      key   ENV[ 'SAMBANOVA_API_KEY' ]
      chat_options do
        model                 'Meta-Llama-3.1-70B-Instruct'
        max_tokens            20
        temperature           0
        stop                  'five'
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence'
  include_examples 'chat requests with error response'
  include_examples 'chat requests without alternating roles'

end
