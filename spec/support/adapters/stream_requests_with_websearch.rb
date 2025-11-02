require 'spec_helper'

RSpec.shared_examples 'stream requests with web search' do | options = {} |

  # note that there is no practical way to determine if a web search happen except to verify citations
  # so the expectation of the adapter is that it will enable citations
  context 'where there is one message which requires a web search' do
    it 'responds with the appropriate generated text' do 

      conversation = create_conversation_without_system_message( "what is the top news item today?\n" )      
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
      expect( response.result.choices.length ).to eq( 1 )

      choice = response.result.choices.first
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
 
      contents = choice.message.contents

      expect( contents.length ).to be >= 1 
      expect( contents.any? { | c | c.is_a?( Intelligence::MessageContent::WebReference ) } ).to be true
    end
  end

end
