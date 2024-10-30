require 'spec_helper'
require 'debug'

RSpec.shared_examples 'chat requests with parallel tools' do | options = {} |

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

  context 'where there is a single message requiring parallel tool calls' do
    it 'responds with mulitple tool requests' do

      response = nil
      conversation = create_conversation( 
        "What is the weather in London, Paris and Rome right now?\n" 
      )
      conversation.append_tool( get_weather_tool )
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
      expect( choice.message.contents.length ).to be >= 3
      choice.message.contents.last( 3 ).each do | content |
        expect( content ).to be_a( Intelligence::MessageContent::ToolCall )
        expect( content.tool_name ).to eq( 'get_weather' )
        expect( content.tool_parameters[ :city ] ).to match( /paris|london|rome/i )
      end
     
    end
  end 

end
