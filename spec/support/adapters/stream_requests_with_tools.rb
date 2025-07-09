require 'spec_helper'
require 'debug'

RSpec.shared_examples 'stream requests with tools' do | options = {} |

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

  context 'where there is a single message and a single tool' do
    it 'streams a tool request' do

      response = nil
      conversation = create_conversation( "Where am I located?\n" )

      contents = []
      adapter = send( options[ :adapter ] || :adapter ) 
      response = create_and_make_stream_request( adapter, conversation, tools: [ get_location_tool ] ) do | result |
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
    
      # test of collected contents
      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1
      expect( tool_calls.last.tool_name ).to eq( 'get_location' )

      # separate test of response payload
      contents = choice.message.contents
      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1
      expect( tool_calls.last.tool_name ).to eq( 'get_location' )

    end
  end 

  context 'where there are multiple messages and a single tool' do
    it 'streams a tool request' do

      conversation = create_conversation( 
        "I am in Seattle, WA\n",
        "Got it! Let me know if you need any local insights or information related to Seattle!\n",
        "What is the current weather?\n"
      )

      contents = []
      adapter = send( options[ :adapter ] || :adapter ) 
      response = create_and_make_stream_request( adapter, conversation, tools: [ get_weather_tool ] ) do | result |
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

      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1

      tool_call = tool_calls.first
      expect( tool_call.tool_name ).to eq( 'get_weather' )
      expect( tool_call.tool_parameters ).to be_a( Hash )
      expect( tool_call.tool_parameters[ :city ] ).to match( /seattle/i )

      contents = choice.message.contents
      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1

      tool_call = tool_calls.first
      expect( tool_call.tool_name ).to eq( 'get_weather' )
      expect( tool_call.tool_parameters ).to be_a( Hash )
      expect( tool_call.tool_parameters[ :city ] ).to match( /seattle/i )

    end
  end

  context 'where there is a single message and a multiple tools' do
    it 'streams the correct tool request' do

      conversation = create_conversation( "Where am I located?" )
      
      contents = []
      adapter = send( options[ :adapter ] || :adapter ) 
      tools =  [ get_location_tool, get_weather_tool ]
      response = create_and_make_stream_request( adapter, conversation, tools: tools ) do | result |
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

      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1

      tool_call = tool_calls.first
      expect( tool_call.tool_name ).to eq( 'get_location' )

      contents = choice.message.contents
      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1

      tool_call = tool_calls.first
      expect( tool_call.tool_name ).to eq( 'get_location' )

    end
  end 

  context 'where there are multiple messages and a mulitple tools' do
    it 'streams the correct tool request' do

      conversation = create_conversation( 
        "I am in Seattle, WA\n",
        "Got it! Let me know if you need any local insights or information related to Seattle!\n",
        "What is the current weather?\n"
      )
      
      contents = []
      adapter = send( options[ :adapter ] || :adapter ) 
      tools = [ get_location_tool, get_weather_tool ]
      response = create_and_make_stream_request( adapter, conversation, tools: tools ) do | result |

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

      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1

      tool_call = tool_calls.last 
      expect( tool_call.tool_name ).to eq( 'get_weather' )
      expect( tool_call.tool_parameters ).to be_a( Hash )
      expect( tool_call.tool_parameters[ :city ] ).to match( /seattle/i )

      contents = choice.message.contents
      expect( contents.length ).to be > 0
      tool_calls = contents.select { | content | content.is_a?( Intelligence::MessageContent::ToolCall ) }
      expect( tool_calls.length ).to be 1

      tool_call = tool_calls.last 
      expect( tool_call.tool_name ).to eq( 'get_weather' )
      expect( tool_call.tool_parameters ).to be_a( Hash )
      expect( tool_call.tool_parameters[ :city ] ).to match( /seattle/i )


   end
  end

  context 'where there is a conversation with a single tool' do 
    context 'which is composed of a text message, a tool request, and a tool response' do
      it 'streams the appropriate generated text' do

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
    
        contents = []
        adapter = send( options[ :adapter ] || :adapter ) 
        tools = [ get_location_tool ]
        response = create_and_make_stream_request( adapter, conversation, tools: tools ) do | result |
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
        expect( choice.end_reason ).to eq( :ended )

        expect( contents.length ).to be > 0
        expect( contents.last ).to be_a( Intelligence::MessageContent::Text )
        expect( contents.last.text ).to match( /seattle/i )

        contents = choice.message.contents
        expect( contents.length ).to be > 0
        expect( contents.last ).to be_a( Intelligence::MessageContent::Text )
        expect( contents.last.text ).to match( /seattle/i )

      end
    end
  end 
  
  context 'where there is a conversation with mutiple tools' do 
    context 'which is composed of a text message, a tool request, and a tool response' do
      it 'streams the appropriate generated text' do

        response = nil
        conversation = Intelligence::Conversation.build do 
          system_message do 
            content text: "You are a helpfull assistant who answers questions succinctly."
          end
          message role: :user do 
            content text: 'What is the current weather?'
          end 
          message role: :assistant do
            content type: :tool_call do
              tool_call_id "MpfiuoRaM"
              tool_name "get_location"
            end
          end
          message role: :user do 
            content type: :tool_result do 
              tool_call_id "MpfiuoRaM"
              tool_name "get_location"
              tool_result "Seattle, WA, USA"
            end 
          end 
        end 
       
        contents = []
        adapter = send( options[ :adapter ] || :adapter ) 
        tools =  [ get_location_tool, get_weather_tool ]
        response = create_and_make_stream_request( adapter, conversation, tools: tools ) do | result |

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

        expect( contents.length ).to be > 0
        expect( contents.last ).to be_a( Intelligence::MessageContent::ToolCall )

        tool_call = contents.last 
        expect( tool_call.tool_name ).to eq( 'get_weather' )
        expect( tool_call.tool_parameters ).to be_a( Hash )
        expect( tool_call.tool_parameters[ :city ] ).to match( /seattle/i )

        contents = choice.message.contents
        expect( contents.length ).to be > 0
        expect( contents.last ).to be_a( Intelligence::MessageContent::ToolCall )

        tool_call = contents.last 
        expect( tool_call.tool_name ).to eq( 'get_weather' )
        expect( tool_call.tool_parameters ).to be_a( Hash )
        expect( tool_call.tool_parameters[ :city ] ).to match( /seattle/i )

      end
    end
  end 

end
