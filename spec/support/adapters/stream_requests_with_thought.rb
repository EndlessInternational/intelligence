require 'spec_helper'

RSpec.shared_examples 'stream requests with thought' do | options = {} |

  # note that there is no practical way to determine if a web search happen except to verify citations
  # so the expectation of the adapter is that it will enable citations
  context 'where there is a message which requires thought' do
    it 'responds with the appropriate generated text' do 

      conversation = create_conversation_without_system_message( 
        "In a 30-60-90 triangle, the length of the hypotenuse is 6. " +
        "What is the length of the shortest side?\n" 
      )
      
      response = create_and_make_stream_request( send( options[ :adapter ] || :adapter ), conversation ) do | result | 
        expect( result ).to be_a( Intelligence::ChatResult )
        expect( result.choices ).not_to be_nil
        expect( result.choices.length ).to eq( 1 )
        
        choice = result.choices.first
        expect( choice.message ).to be_a( Intelligence::Message )
        expect( choice.message.contents ).not_to be_nil
      end
      
      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).not_to be_nil
      expect( response.result ).to respond_to( :message )
      expect( response.result.message ).not_to be_nil

      contents = response.result.message.contents
      expect( contents ).not_to be_nil
      expect( contents.length ).to be >= 1 
      expect( contents.any? { | c | c.is_a?( Intelligence::MessageContent::Thought ) } ).to be true
      contents.each do | content |
        if content.is_a?( Intelligence::MessageContent::Thought )
          expect( content.text ).not_to be_nil
          expect( content.text.length ).to be >= 1 
        end
      end

    end
  end

end
