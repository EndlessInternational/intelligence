require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :anthropic ]} chat requests", :anthropic do

  include_context 'vcr'

  before do
    raise "An ANTHROPIC_API_KEY must be defined in the environment." unless ENV[ 'ANTHROPIC_API_KEY' ]
  end

  let( :adapter_with_invalid_key ) do
    Intelligence::Adapter[ :anthropic ].build! do 
      key                     'this-key-is-not-valid'  
      chat_options do
        model                 'claude-3-5-sonnet-20240620'
        max_tokens            24
        temperature           0
      end
    end
  end

  let( :adapter ) do
    Intelligence::Adapter[ :anthropic ].build! do   
      key   ENV[ 'ANTHROPIC_API_KEY' ]
      chat_options do
        model                 'claude-3-5-sonnet-20240620'
        max_tokens            24 
        temperature           0
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :anthropic ].build! do   
      key   ENV[ 'ANTHROPIC_API_KEY' ]
      chat_options do
        model                 'claude-3-5-sonnet-20240620'
        max_tokens            24
        temperature           0
        stop                  'five'
      end
    end
  end

  include_examples 'chat requests'
  include_examples 'chat requests with token limit exceeded'
  include_examples 'chat requests with stop sequence', 
                   adapter: :adapter_with_stop_sequence, end_reason: :end_sequence_encountered   
  include_examples 'chat requests with error response'
  include_examples 'chat requests without alternating roles'
  include_examples 'chat requests with binary encoded images'
  
end
