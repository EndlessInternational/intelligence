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
            "the secret word is 'red'\n",
            "ok\n",
            "what is the exact secret word? answer with the word only\n" 
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
          match( /red/i )
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
            "the secret word is 'blue'\n",
            "ok\n",
            "what is the secret word?\nrespond with the word only\n"          
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
          match( /blue/i )
        )

      end 

    end
  end

  context 'where there are muliple chat request in a series' do 
    
    context 'where there is no system message' do 
      context 'where there is a single message' do

        it 'responds with the appropriate generated text' do

          response = nil
          conversation = create_conversation_without_system_message( "respond only with the word 'hello'\n" )
          response = create_and_make_chat_request( adapter, conversation ) 
          expect( response.success? ).to be( true ), response_error_description( response )
          expect( response.result ).to be_a( Intelligence::ChatResult )
          expect( response.result.text ).to match( /hello/i )

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

          response = nil
          conversation = create_conversation_without_system_message( "respond only with the word 'hello'\n" )
          response = create_and_make_chat_request( adapter, conversation ) 
          expect( response.success? ).to be( true ), response_error_description( response )
          expect( response.result ).to be_a( Intelligence::ChatResult )
          expect( response.result.text ).to match( /hello/i )

          response = create_and_make_chat_request(
            adapter, 
            create_conversation_without_system_message( 
              "the secret word is 'blue'\n",
              "ok\n",
              "what is the secret word?\nrespond with the word only\n"          
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
            match( /blue/i )
          )

        end 

      end
    end

    context 'where there is a system message' do 
      context 'where there is a single message' do

        it 'responds with the appropriate generated text' do
 
          response = nil
          conversation = create_conversation_without_system_message( "respond only with the word 'hello'\n" )
          response = create_and_make_chat_request( adapter, conversation ) 
          expect( response.success? ).to be( true ), response_error_description( response )
          expect( response.result ).to be_a( Intelligence::ChatResult )
          expect( response.result.text ).to match( /hello/i )

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
  
          response = nil
          conversation = create_conversation_without_system_message( "respond only with the word 'hello'\n" )
          response = create_and_make_chat_request( adapter, conversation ) 
          expect( response.success? ).to be( true ), response_error_description( response )
          expect( response.result ).to be_a( Intelligence::ChatResult )
          expect( response.result.text ).to match( /hello/i )

         response = create_and_make_chat_request(
            adapter, 
            create_conversation( 
              "the secret word is 'blue'\n",
              "ok\n",
              "what is the secret word?\nrespond with the word only\n"             
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
            match( /blue/i )
          )

        end 

      end
    end
  end

end
