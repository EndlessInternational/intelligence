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

  context 'where there is a single message that ends at stop sequence' do
    it 'responds with generated text up to the stop sequence and an end reason indicating a stop sequence was encountered' do

      response = create_and_make_chat_request(
        adapter_with_stop_sequence, 
        create_conversation( "count to ten in words, all lower case, one word per line\n" )
      )

      expect( response.success? ).to be true
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :end_sequence_encountered )
      expect( choice.end_sequence ).to eq( 'five' )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to eq( 1 )

      text = message_contents_to_text( choice.message )
      expect( text  ).to match( /four/i )
      expect( text  ).to_not match( /five/i )

    end
  end

  context 'where there are multiple messages and the last ends at stop sequence' do
    it 'responds with generated text up to the stop sequence and an end reason indicatng a stop sequence was encountered' do 

      response = create_and_make_chat_request(
        adapter_with_stop_sequence, 
        create_conversation( 
          "count to five in words, one word per line\n",
          "one\ntwo\nthree\nfour\nfive\n",
          "count to ten in words, one word per line\n"
        )
      )
      
      expect( response.success? ).to be true
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :end_sequence_encountered )
      expect( choice.end_sequence ).to eq( 'five' )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to eq( 1 )

      text = message_contents_to_text( choice.message )
      expect( text  ).to match( /four/i )
      expect( text  ).to_not match( /five/i )

    end
  end

  include_examples 'chat requests with error response'
  include_examples 'chat requests without alternating roles'
  include_examples 'chat requests with binary encoded images'
  
end
