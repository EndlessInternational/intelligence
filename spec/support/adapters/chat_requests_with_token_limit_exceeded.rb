require 'spec_helper'

RSpec.shared_examples 'chat requests with token limit exceeded' do 

  context 'where there is a single message the response to which will exceed the token limit' do
    it 'responds with limited text and an end reason which indicates that the token limit was exceeded' do
    
      response = create_and_make_chat_request(
        adapter, 
        create_conversation( "count to twenty in words, all lower case, one word per line\n" )
      )
      
      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :token_limit_exceeded )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to eq( 1 )
      expect( message_contents_to_text( choice.message ) ).to( 
        match( /five/i )
      )

    end 
  end

  context 'where there are multiple messages the response to which will exceed the token limit' do
    it 'responds with limited text and an end reason which indicates that the token limit was exceeded' do

      response = create_and_make_chat_request(
        adapter, 
        create_conversation( 
          "count to five in words, all lower case, one word per line\n",
          "one\ntwo\nthree\nfour\nfive\n",
          "count to twenty in words, all lower case, one word per line\n"
        )
      )
      
      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :token_limit_exceeded )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to eq( 1 )
      expect( message_contents_to_text( choice.message ) ).to( 
        match( /five/i )
      )

    end
  end

end
