require 'spec_helper'

RSpec.shared_examples 'stream requests with binary encoded pdf' do 

  let( :binary_content_of_nasa_pdf_file ) {
    build_binary_content( fixture_file_path( 'nasa.pdf'  ) )
  }

  let( :binary_content_of_nasa_mars_curiosity_pdf_file ) {
    build_binary_content( fixture_file_path( 'nasa-mars-curiosity.pdf'  ) )
  }

  context 'where there is a single message and an encoded pdf' do 
    it 'responds with the appropriate generated text' do

      conversation = create_conversation( "what is the title of the attached file?\n" )
      conversation.messages.last.append_content( binary_content_of_nasa_pdf_file )

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
        match( /vision for space exploration/i ), 
        "Expected 'vision for space exploration', received '#{text}'."
      )

    end
  end

  context 'where there are multiple messages with the first including a binary encoded pdf' do
    it 'responds with the appropriate generated text' do

      conversation = create_conversation( "what is the title of the attached file?\n" )
      conversation.messages.last.append_content( binary_content_of_nasa_pdf_file )
      conversation.messages << build_text_message( :assistant, "Vision for Space Exploration\n" )
      conversation.messages << build_text_message( :user, "when was it written?\n" )

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
        match( /February 2004/i ),
        "Expected 'February 2004', received '#{text}'."
      )

    end
  end 

  context 'where there are multiple messages with each including a binary encoded pdf' do
    it 'responds with the appropriate generated text' do

      conversation = create_conversation( "what is the title of the attached file?\n" )
      conversation.messages.last.append_content( binary_content_of_nasa_pdf_file )
      conversation.messages << build_text_message( :assistant, "Vision for Space Exploration\n" )
      message = build_text_message( :user, "what about this document? describe it in less than 16 words\n" )
      message.append_content( binary_content_of_nasa_mars_curiosity_pdf_file )
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
        match( /mars/i ),
        "Expected 'mars', received '#{text}'."
      )

    end
  end

end
