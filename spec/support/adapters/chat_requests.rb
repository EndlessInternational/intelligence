require 'spec_helper'

RSpec.shared_examples 'chat requests' do 

  context 'where there is no system message' do 
    context 'where there is a single message' do

      it 'responds with the appropriate generated text' do

        response = nil
        conversation = create_conversation_without_system_message( "respond only with the word 'hello'\n" )
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
          match( /hello/i )
        )

      end

    end 

    context 'where there are multiple messages' do
      it 'responds with the appropriate generated text' do

        response = create_and_make_chat_request(
          adapter, 
          create_conversation_without_system_message( 
            "this is a test, respond with 'test'\n",
            "test\n",
            "what was the user message before this one?\nrespond in less than 16 words\n"
          )
        )
        
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
          match( /this is a test|respond with/i )
        )

      end 

    end
  end

  context 'where there is a system message' do 
    context 'where there is a single message' do

      it 'responds with the appropriate generated text' do

        response = nil
        conversation = create_conversation( "respond only with the word 'hello'\n" )
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
          match( /hello/i )
        )

      end

    end 

    context 'where there are multiple messages' do
      it 'responds with the appropriate generated text' do

        response = create_and_make_chat_request(
          adapter, 
          create_conversation( 
            "this is a test, respond with 'test'\n",
            "test\n",
            "what was the user message before this one?\nrespond in less than 16 words\n"
          )
        )
        
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
          match( /this is a test|respond with/i )
        )

      end 

    end
  end

end
