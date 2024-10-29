require 'spec_helper'

RSpec.shared_examples 'stream requests without alternating roles' do 

  context 'where there are two messages with the same role in a sequence' do
    it 'streams the appropriate generated text' do 

      conversation = create_conversation( 
        "this is a test, respond with 'test'\n",
        "test\n"
      )
      conversation.messages << build_text_message( :user, "hello!\n" )
      conversation.messages << build_text_message( :user, "what was the previous user message?\n" )

      text = ''
      response = create_and_make_stream_request( adapter, conversation ) do | result | 
        
        expect( result ).to be_a( Intelligence::ChatResult )
        expect( result.choices ).not_to be_nil
        expect( result.choices.length ).to eq( 1 )
        
        choice = result.choices.first
        expect( choice.message ).to be_a( Intelligence::Message )
        expect( choice.message.contents ).not_to be_nil

        text += message_contents_to_text( choice.message )

      end
      
      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :ended )

      expect( text ).to( match( /this is a test|hello/i ) )

    end
  end

end
