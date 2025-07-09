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
        max_tokens            128 
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_limited_max_tokens ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'gpt-4o'
        max_tokens            16 
        temperature           0

        stream                true
      end
    end
  end

  let( :adapter_with_thought ) do
    Intelligence::Adapter[ :open_ai ].build! do   
      key                     ENV[ 'OPENAI_API_KEY' ]
      chat_options do
        model                 'o4-mini'
        max_tokens            4096
        reasoning do 
          effort              :low
          summary             :detailed
        end

        stream                true
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

        stream                true
      end
    end
  end

  include_examples 'stream requests'
  include_examples 'stream requests with token limit exceeded',
                   adapter: :adapter_with_limited_max_tokens
  include_examples 'stream requests with binary encoded images'
  include_examples 'stream requests with file images'
  include_examples 'stream requests with thought', 
                   adapter: :adapter_with_thought
                   
  include_examples 'stream requests without alternating roles'
  include_examples 'stream requests with tools'
  include_examples 'stream requests with parallel tools'
  include_examples 'stream requests with tools multiturn'
  include_examples 'stream requests with web search',
                   adapter: :adapter_with_web_search

end
