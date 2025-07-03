require 'spec_helper'

RSpec.shared_examples 'chat requests with thought' do | options = {} |

  context 'where there is a message which requires thought' do
    it 'responds with the appropriate generated text' do 

      conversation = create_conversation(         
        "In a 30-60-90 triangle, the length of the hypotenuse is 6. " +
        "What is the length of the shortest side?\n"  
      )     
      response = create_and_make_chat_request( send( options[ :adapter ] || :adapter ), conversation )

      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :ended )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to be >= 1 

      contents = choice.message.contents
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
