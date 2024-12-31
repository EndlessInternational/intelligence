require 'spec_helper'

RSpec.shared_examples 'chat requests without alternating roles' do 

  context 'where there are two messages with the same role in a sequence' do
    it 'responds with the appropriate generated text' do 

      conversation = create_conversation( 
        "the secret word is 'blue'\n",
        "ok\n"
      )
      conversation.messages << build_text_message( :user, "the secret word has been changed to 'red'!\n" )
      conversation.messages << build_text_message( :user, "what is the secret word?\n" )
     
      response = create_and_make_chat_request( adapter, conversation )
      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :ended )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to eq( 1 )
      expect( message_contents_to_text( choice.message ) ).to( 
        match( /red/i )
      )

    end
  end

end
