require 'spec_helper'

RSpec.shared_examples 'chat requests with stop sequence' do | options = {} |  

  context 'where there is a single message that ends at stop sequence' do
    it 'responds with generated text up to the stop sequence' do

      response = create_and_make_chat_request(
        send( options[ :adapter ] || :adapter ), 
        create_conversation( "count to ten in words, all lower case, one word per line\n" )
      )

      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( options[ :end_reason ] || :ended )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to eq( 1 )

      text = message_contents_to_text( choice.message )
      expect( text  ).to match( /four/i )
      expect( text  ).to_not match( /five/i )

    end 
  end

  context 'where there are multiple messages and the last ends at stop sequence' do
    it 'responds with generated text up to the stop sequence' do 

      response = create_and_make_chat_request(
        send( options[ :adapter ] || :adapter ), 
        create_conversation( 
          "count to five in words, one word per line\n",
          "one\ntwo\nthree\nfour\nfive\n",
          "count to ten in words, one word per line\n"
        )
      )
      
      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( options[ :end_reason ] || :ended )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to eq( 1 )

      text = message_contents_to_text( choice.message )
      expect( text  ).to match( /four/i )
      expect( text  ).to_not match( /five/i )

    end 
  end

end
