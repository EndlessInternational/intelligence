require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :samba_nova ]} stream requests", :samba_nova do

  include_context 'vcr'

  before do 
    raise "An SAMBANOVA_API_KEY must be defined in the environment." unless ENV[ 'SAMBANOVA_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :samba_nova ].build! do   
      key                     ENV[ 'SAMBANOVA_API_KEY' ]
      chat_options do
        model                 'Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :samba_nova ].build! do   
      key   ENV[ 'SAMBANOVA_API_KEY' ]
      chat_options do
        model                 'Meta-Llama-3.1-70B-Instruct'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence', adapter: :adapter_with_stop_sequence  
  include_examples 'stream requests without alternating roles'

end
