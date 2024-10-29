require 'spec_helper'
require 'debug'

RSpec.shared_examples 'chat requests with complex tools' do | options = {} |

  let( :get_complex_weather_tool ) {
    Intelligence::Tool.build! do
      name :get_weather 
      description 'The get_weather tool returns the current weather in given locality.'
      argument name: :location, required: true, type: 'object' do  
        description "The locality for which the weather will be returned"
        property name: :city, type: 'string', required: true do 
          description "The city or town for which the current weather should be returned."
        end 
        property name: :state, type: 'string' do 
          description \
            "The state or province for which the current weather should be returned. If this is " \
            "not provided the largest or most prominent city with the given name, in the given " \
            "country or in the worldi, will be assumed."
        end  
        property name: :country, type: 'string' do 
          description \
            "The country for which the given weather should be returned. If this is not provided " \
            "the largest or most prominent city with the given name will be returned."
        end 
      end 
    end 
  }

  context 'where there is a single message and a single tool' do
    context 'where the tool parameters include an object' do 
      it 'responds with a tool request' do

        response = nil
        conversation = create_conversation( "Tell me the weather in Seattle.\n" )
        conversation.append_tool( get_complex_weather_tool )
        response = create_and_make_chat_request( send( options[ :adapter ] || :adapter ), conversation ) 
        
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
        expect( tool_call.tool_parameters ).to be_a( Hash )
        expect( tool_call.tool_parameters[ :location ] ).to be_a( Hash )
        expect( tool_call.tool_parameters[ :location ][ :city ] ).to match( /seattle/i )

      end
    end
  end

  context 'where there are multiple messages and a single tool' do
    context 'where the tool parameters include are an object' do 
      it 'responds with a tool request' do

        conversation = create_conversation( 
          "I am in Seattle, WA\n",
          "Got it! Let me know if you need any local insights or information related to Seattle!\n",
          "What is the current weather?\n"
        )
        conversation.append_tool( get_complex_weather_tool )
        response = create_and_make_chat_request( send( options[ :adapter ] || :adapter ), conversation )

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
        expect( tool_call.tool_parameters ).to be_a( Hash )
        expect( tool_call.tool_parameters[ :location ] ).to be_a( Hash )
        expect( tool_call.tool_parameters[ :location ][ :city ] ).to match( /seattle/i )

      end
    end
  end

end
