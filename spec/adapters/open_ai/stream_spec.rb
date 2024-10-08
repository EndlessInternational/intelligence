require 'spec_helper'

RSpec.describe "#{Intelligence::Adapter[ :open_ai ]} stream requests", :open_ai do

  include_context 'vcr'

  before do 
    raise "An OPENAI_API_KEY must be defined in the environment." unless ENV[ 'OPENAI_API_KEY' ]
  end

  let( :adapter ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        max_completion_tokens 24
        temperature           0

        stream                true
        stream_options do
          include_usage       true
        end
      end
    end
  end

  let( :adapter_with_stop_sequence ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key   ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        max_tokens            16
        temperature           0
        stop                  'five'

        stream                true
        stream_options do
          include_usage       true
        end
      end
    end
  end

  let( :vision_adapter ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o-mini'
        max_completion_tokens 24
        temperature           0

        stream                true
        stream_options do
          include_usage       true
        end
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded'
  include_examples 'stream requests with stop sequence'
  include_examples 'stream requests with images'
  include_examples 'stream requests without alternating roles'

end
