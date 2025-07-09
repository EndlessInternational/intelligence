require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :anthropic ]} stream requests", :anthropic do

  include_context 'vcr'

  before do
    raise "An ANTHROPIC_API_KEY must be defined in the environment." unless ENV[ 'ANTHROPIC_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :anthropic ].build! do   
      key                     ENV[ 'ANTHROPIC_API_KEY' ]
      chat_options do
        model                 'claude-3-5-sonnet-20240620'
        max_tokens            256 
        temperature           0
        stream                true
      end
    end
  end

  let( :adapter_with_thought ) do
    Intelligence::Adapter[ :anthropic ].build! do   
      key                     ENV[ 'ANTHROPIC_API_KEY' ]
      chat_options do
        model                 'claude-sonnet-4-20250514'
        max_tokens            4096
        thinking do
          budget_tokens       2048
        end
        stream                true
      end
    end
  end

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :anthropic ].build! do   
      key                     ENV[ 'ANTHROPIC_API_KEY' ]
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
      key                     ENV[ 'ANTHROPIC_API_KEY' ]
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
  include_examples 'stream requests without alternating roles'

  include_examples 'stream requests with token limit exceeded',
                   adapter: :adapter_with_limited_max_tokens
  include_examples 'stream requests with stop sequence',
                   adapter: :adapter_with_stop_sequence, 
                   end_reason: :end_sequence_encountered

  include_examples 'stream requests with binary encoded images'
  include_examples 'stream requests with file images'
  # include_examples 'stream requests with binary encoded pdf'

  include_examples 'stream requests with thought', 
                   adapter: :adapter_with_thought

  include_examples 'stream requests with tools'
  include_examples 'stream requests with parallel tools'

  include_examples 'stream requests with tools multiturn'

end
