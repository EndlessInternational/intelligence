require 'spec_helper'

RSpec.shared_examples 'chat requests with error response' do  

  context 'where the adapter is configured with an invalid key' do
    it 'responds with an authentication error' do

      response = create_and_make_chat_request(
        adapter_with_invalid_key, 
        create_conversation( "respond only with the word 'hello'\n" )
      )

      expect( response.success? ).to be( false )
      expect( response.result ).to be_a( Intelligence::ChatErrorResult )
      expect( response.result.error_type ).not_to be_nil
      expect( response.result.error_type ).to eq( 'authentication_error' )

    end
  end

end
