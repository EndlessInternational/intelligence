require 'spec_helper'

RSpec.shared_examples 'chat requests with images' do 

  let( :binary_content_of_red_balloon ) {
    build_binary_content( fixture_file_path( 'single-red-balloon.png'  ) )
  }

  let( :binary_content_of_three_balloons ) {
    build_binary_content( fixture_file_path( 'three-balloons.png'  ) )
  }

  context 'where there is a single message and an image' do 

  end

  context 'where there are multiple messages with the first including an image' do
    it 'responds with the appropriate generated text' do

      conversation = create_conversation( "identify this image; all lower case\n" )
      conversation.messages.last.append_content( binary_content_of_red_balloon )
      conversation.messages << build_text_message( :assistant, "balloon\n" )
      conversation.messages << build_text_message( :user, "what color?\n" )
      response = create_and_make_chat_request( vision_adapter, conversation )
      
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

  context 'where there are multiple messages with each including an image' do
    it 'responds with the appropriate generated text' do

      conversation = create_conversation( "identify this image; all lower case\n" )
      conversation.messages.last.append_content( binary_content_of_red_balloon )
      conversation.messages << build_text_message( :assistant, "one red balloon\n" )
      message = build_text_message( :user, "what about this image?\n" )
      message.append_content( binary_content_of_three_balloons )
      conversation.messages << message 
      response = create_and_make_chat_request( vision_adapter, conversation )
      
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
        match( /balloons/i )
      )

    end
  end

end