require 'spec_helper'
require 'debug'

RSpec.shared_examples 'stream requests with parallel tools' do | options = {} |

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
    it 'streams mulitple tool calls' do

      response = nil
      conversation = create_conversation( 
        "What is the weather in London, Paris and Rome right now?\n" 
      )
      conversation.append_tool( get_weather_tool )
      
      contents = []
      response = create_and_make_stream_request( send( options[ :adapter ] || :adapter ), conversation ) do | result |    
        expect( result ).to be_a( Intelligence::ChatResult )
        expect( result.choices ).not_to be_nil
        expect( result.choices.length ).to eq( 1 )
        expect( result.choices.first ).to be_a( Intelligence::ChatResultChoice )

        choice = result.choices.first
        expect( choice.message ).to be_a( Intelligence::Message )
        expect( choice.message.contents ).not_to be_nil
     
        contents_fragments = choice.message.contents 
        contents.fill( nil, contents.length..(contents_fragments.length - 1) )

        contents_fragments.each_with_index do | contents_fragment, index |
          contents[ index ] = contents[ index ].nil? ? 
            contents_fragment : 
            contents[ index ].merge( contents_fragment )
        end
      end

      expect( response.success? ).to be( true ), response_error_description( response )
      
      choice = response.result.choices.first 
      expect( choice.end_reason ).to eq( :tool_called )

      expect( contents.length ).to be >= 3
      expect( contents.last ).to be_a( Intelligence::MessageContent::ToolCall )

      tool_calls = contents.last( 3 ).each do | tool_call |
        expect( tool_call.tool_call_id ).not_to be_nil
        expect( tool_call.tool_name ).to eq( 'get_weather' )
        expect( tool_call.tool_parameters ).to be_a( Hash )
        expect( tool_call.tool_parameters[ :city ] ).to match( /london|paris|rome|/i )
      end
    end
  end 

end
