require 'spec_helper'
require 'debug'

RSpec.shared_examples 'stream requests with tools multiturn' do | options = {} |

  let( :get_location_tool ) {
    Intelligence::Tool.build! do  
      name :get_location 
      description \
        "The get_location tool will return the users city, state or province and country."
    end
  }

  let( :get_weather_tool ) {
    Intelligence::Tool.build! do  
      name :get_weather
      description "The get_weather tool will return the current weather in a given locality."
      argument name: :city, type: 'string', required: true do 
        description "The city or town for which the current weather should be returned."
      end 
      argument name: :state, type: 'string' do 
        description \
          "The state or province for which the current weather should be returned. If this is " \
          "not provided the largest or most prominent city with the given name, in the given " \
          "country or in the worldi, will be assumed."
      end  
      argument name: :country, type: 'string' do 
        description \
          "The country for which the given weather should be returned. If this is not provided " \
          "the largest or most prominent city with the given name will be returned."
      end 
    end
  }
  
  context 'where there is a conversation with mutiple tools' do 

    context 'which requires multiple tools to complete' do
      it 'responds with the appropriate generated text' do

        response = nil
        conversation = Intelligence::Conversation.build do 
          system_message do 
            content text: "You are a helpfull assistant who answers questions succinctly."
          end
          message role: :user do 
            content text: 'What is the current weather?'
          end 
        end 

        response = create_and_make_stream_request( 
          send( options[ :adapter ] || :adapter ), 
          conversation, 
          tools: [ get_location_tool, get_weather_tool ]
        )
        
        expect( response.success? ).to be( true ), response_error_description( response )
        expect( response.result ).to be_a( Intelligence::ChatResult )
        expect( response.result.choices ).not_to be_nil
        expect( response.result.choices.length ).to eq( 1 )
        expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

        choice = response.result.choices.first
        expect( choice.end_reason ).to eq( :tool_called  )
        expect( choice.message ).to be_a( Intelligence::Message )
        expect( choice.message.contents ).not_to be_nil
        expect( choice.message.contents.length ).to be > 0
        expect( choice.message.contents.last ).to be_a( Intelligence::MessageContent::ToolCall )
       
        tool_call = choice.message.contents.last
        expect( tool_call.tool_name ).to eq( 'get_location' )

        conversation << choice.message
        conversation << Intelligence::Message.build!( role: :user ) do 
          content type: :tool_result do  
            tool_call_id tool_call.tool_call_id 
            tool_name tool_call.tool_name
            tool_result( "Seattle, WA, USA" )
          end
        end

        response = create_and_make_stream_request( 
          send( options[ :adapter ] || :adapter ), 
          conversation, 
          tools: [ get_location_tool, get_weather_tool ]
        )

        expect( response.success? ).to be( true ), response_error_description( response )
        expect( response.result ).to be_a( Intelligence::ChatResult )
        expect( response.result.choices ).not_to be_nil
        expect( response.result.choices.length ).to eq( 1 )
        expect( response.result.choices.first ).to be_a( Intelligence::ChatResultChoice )

        choice = response.result.choices.first
        expect( choice.end_reason ).to eq( :tool_called  )
        expect( choice.message ).to be_a( Intelligence::Message )
        expect( choice.message.contents ).not_to be_nil
        expect( choice.message.contents.length ).to be > 0
        expect( choice.message.contents.last ).to be_a( Intelligence::MessageContent::ToolCall )
       
        tool_call = choice.message.contents.last
        expect( tool_call.tool_name ).to eq( 'get_weather' )

      end
    end

  end 
end
