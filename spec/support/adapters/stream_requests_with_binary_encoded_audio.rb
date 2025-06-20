require 'spec_helper'

RSpec.shared_examples 'stream requests with binary encoded audio' do 

  let( :binary_content_of_test_audio_file ) {
    build_binary_content( fixture_file_path( 'this-is-a-test.mp3'  ) )
  }

  let( :binary_content_of_hello_world_audio_file ) {
    build_binary_content( fixture_file_path( 'hello-world.mp3'  ) )
  }

  context 'where there is a single message and binary encoded audio' do 
    it 'streams the appropriate generated text' do

      conversation = create_conversation( "what is the text in the attached file?\n" )
      conversation.messages.last.append_content( binary_content_of_test_audio_file )

      text = ''
      response = create_and_make_stream_request( vision_adapter, conversation ) do | result | 
        
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
  
      expect( text ).to( 
        match( /this is a test/i ), 
        "Expected 'this is a test', received '#{text}'."
      )

    end
  end

  context 'where there are multiple messages with the first including binary encoded audio' do
    it 'streams the appropriate generated text' do

      conversation = create_conversation( "what is the text in the attached file?\n" )
      conversation.messages.last.append_content( binary_content_of_test_audio_file )
      conversation.messages << build_text_message( :assistant, "this is a test\n" )
      conversation.messages << build_text_message( :user, "how many words is that?\nreply with just a number\n" )

      text = ''
      response = create_and_make_stream_request( vision_adapter, conversation ) do | result | 
        
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

      expect( text ).to( 
        match( /4/i ), 
        "Expected '4', received '#{text}'."
      )

    end
  end 

  context 'where there are multiple messages with each including binary encoded audio' do
    it 'streams the appropriate generated text' do

      conversation = create_conversation( "what is the text in the attached file?\n" )
      conversation.messages.last.append_content( binary_content_of_test_audio_file )
      conversation.messages << build_text_message( :assistant, "this is a test\n" )
      message = build_text_message( :user, "what about this file?\n" )
      message.append_content( binary_content_of_hello_world_audio_file )
      conversation.messages << message 

      text = ''
      response = create_and_make_stream_request( vision_adapter, conversation ) do | result | 
        
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

      expect( text ).to( 
        match( /hello world/i ), 
        "Expected 'hello world', received '#{text}'."
      )

    end
  end

end
