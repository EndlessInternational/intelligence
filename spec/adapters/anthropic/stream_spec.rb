require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :anthropic ]} stream requests", :anthropic do

  include_context 'vcr'

  before do
    raise "An ANTHROPIC_API_KEY must be defined in the environment." unless ENV[ 'ANTHROPIC_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :anthropic ].build! do   
      key   ENV[ 'ANTHROPIC_API_KEY' ]
      chat_options do
        model                 'claude-3-5-sonnet-20240620'
        max_tokens            24
        temperature           0
        stream                true
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :anthropic ].build! do   
      key   ENV[ 'ANTHROPIC_API_KEY' ]
      chat_options do
        model                 'claude-3-5-sonnet-20240620'
        max_tokens            16
        stop                  'five'
        temperature           0
        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence',
                   adapter: :adapter_with_stop_sequence, end_reason: :end_sequence_encountered
  include_examples 'stream requests with binary encoded images'
  include_examples 'stream requests without alternating roles'

end
