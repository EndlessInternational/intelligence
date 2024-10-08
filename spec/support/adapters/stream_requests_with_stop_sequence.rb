require 'spec_helper'

RSpec.shared_examples 'stream requests with stop sequence' do 

  context 'where there is a single message that ends at stop sequence' do
    it 'responds with generated text up to the stop sequence' do

      conversation = create_conversation( "count to twenty in words, all lower case, one word per line\n" )
      
      text = ''
      response = create_and_make_stream_request( adapter_with_stop_sequence, conversation ) do | result | 
        
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
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )
      expect( response.result.choices.first.end_reason ).to eq( :ended )

      expect( text  ).to match( /four/i )
      expect( text  ).to_not match( /five/i )

    end
  end

  context 'where there are multiple messages and the last ends at stop sequence' do
    it 'responds with generated text up to the stop sequence' do 

      conversation =  create_conversation( 
        "count to five in words, all lower case, one word per line\n",
        "one\ntwo\nthree\nfour\nfive\n",
        "count to twenty in words, all lower case, one word per line\n"
      )
      
      text = ''
      response = create_and_make_stream_request( adapter_with_stop_sequence, conversation ) do | result | 
        
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
      expect( response.result.choices.first.end_reason ).to eq( :ended )

      expect( text ).to match( /four/i )
      expect( text ).to_not match( /five/i )

    end
  end

end
