require 'spec_helper'

RSpec.describe Intelligence::MessageContent, :unit do

  describe '.build' do
    context 'when the class for the provided type exists' do
      it 'creates an instance of the correct class' do
        # define a mock class for the test
        class Intelligence::MessageContent::TestType < Intelligence::MessageContent::Base; 
          configuration do 
            parameter :some_attribute
          end
          attr_reader :some_attribute 
        end

        instance = Intelligence::MessageContent.build!( :test_type, some_attribute: 'value' )

        expect( instance ).to be_a( Intelligence::MessageContent::TestType )
        expect( instance.instance_variable_get( '@some_attribute' ) ).to eq( 'value' )
      end
    end
  end

end

