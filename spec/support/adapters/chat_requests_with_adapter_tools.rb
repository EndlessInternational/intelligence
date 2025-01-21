require 'spec_helper'
require 'debug'

RSpec.shared_examples 'chat requests with adapter tools' do | options = {} |

  context 'where there is a single message and a single tool' do
    it 'responds with a tool request' do

      response = nil
      conversation = create_conversation( "Where am I located?\n" )
      response = create_and_make_chat_request( 
        send( options[ :adapter ] || :adapter_with_tool ), 
        conversation       
      ) 
      
      expect( response.success? ).to be( true ), response_error_description( response )
      expect( response.result ).to be_a( Intelligence::ChatResult )
      expect( response.result.choices ).not_to be_nil
      expect( response.result.choices.length ).to eq( 1 )
      expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

      choice = response.result.choices.first
      expect( choice.end_reason ).to eq( :tool_called )
      expect( choice.message ).to be_a( Intelligence::Message )
      expect( choice.message.contents ).not_to be_nil
      expect( choice.message.contents.length ).to be > 0
      expect( choice.message.contents.last ).to be_a( Intelligence::MessageContent::ToolCall )
     
      tool_call = choice.message.contents.last
      expect( tool_call.tool_name ).to eq( 'get_location' )
    end
  end 

  context 'where there is a conversation with a single tool' do 
    context 'which is composed of a text message, a tool request, and a tool response' do
      it 'responds with the appropriate generated text' do

        response = nil
        conversation = Intelligence::Conversation.build do 
          system_message do 
            content text: "You are a helpfull assistant who answers questions succinctly."
          end
          message role: :user do 
            content text: 'Where am I located?'
          end 
          message role: :assistant do
            content type: :tool_call do
              tool_call_id "MpfiuoRaM"
              tool_name :get_location
            end
          end
          message role: :user do 
            content type: :tool_result do 
              tool_call_id "MpfiuoRaM"
              tool_name :get_location
              tool_result "Seattle, WA, USA"
            end 
          end 
        end 

        response = create_and_make_chat_request( 
          send( options[ :adapter ] || :adapter ), 
          conversation, 
          tools: [ get_location_tool ]
        )
        
        expect( response.success? ).to be( true ), response_error_description( response )
        expect( response.result ).to be_a( Intelligence::ChatResult )
        expect( response.result.choices ).not_to be_nil
        expect( response.result.choices.length ).to eq( 1 )
        expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

        choice = response.result.choices.first
        expect( choice.end_reason ).to eq( :ended  )
        expect( choice.message ).to be_a( Intelligence::Message )
        expect( choice.message.contents ).not_to be_nil
        expect( choice.message.contents.length ).to eq( 1 )
        expect( choice.message.contents[ 0 ] ).to be_a( Intelligence::MessageContent::Text )
       
        content = choice.message.contents[ 0 ]
        expect( content.text ).to match( /seattle/i )

      end
    end
  end 

end
