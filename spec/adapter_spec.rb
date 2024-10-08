require 'spec_helper'

# define a minimal adapter class for testing purposes
module Intelligence
  module TestAdapter
    class Adapter < Intelligence::Adapter::Base
      configuration do 
        parameter :key
      end
    end
  end
end

RSpec.describe Intelligence::Adapter, :unit do

  describe '.[]' do

    context 'when adapter_type is nil' do
      it 'raises an ArgumentError' do
        expect {
          described_class[ nil ]
        }.to raise_error( ArgumentError, 'An adapter type is required but nil was given.' )
      end
    end

    context 'when adapter class exists' do
      it 'returns the adapter class' do
        adapter_class = described_class[ :test_adapter ]
        expect( adapter_class ).to eq( Intelligence::TestAdapter::Adapter )
      end
    end

    context 'when adapter class does not exist initially but found after require' do
    
      before do
        Intelligence.send( :remove_const, :TestRequireAdapter ) if Intelligence.const_defined?( :TestRequireAdapter )
        allow( described_class ).to receive( :require ).and_return( true )
        allow( Intelligence ).to receive( :const_get ).with( 'TestRequireAdapter::Adapter' ).and_wrap_original do | original_method, *args |
          if Intelligence.const_defined?( :TestRequireAdapter )
            original_method.call( *args )
          else
            module Intelligence
              module TestRequireAdapter
                class Adapter < Intelligence::Adapter::Base
                end
              end
            end
            original_method.call( *args )
          end
        end
      end

      it 'requires the adapter file and returns the adapter class' do
        adapter_class = described_class[ :test_require_adapter ]
        expect( adapter_class ).to eq( Intelligence::TestRequireAdapter::Adapter )
      end

    end

    context 'when adapter class does not exist and cannot be required' do
      
      before do
        allow( described_class ).to receive( :require ).and_return( false )
      end

      it 'raises an ArgumentError' do
        expect {
          described_class[ :nonexistent_adapter ]
        }.to raise_error( ArgumentError, /The Intelligence adapter file .* is missing or does not define NonexistentAdapter::Adapter./ )
      end

    end

    context 'when adapter class cannot be found after require' do
      
      before do
        allow( described_class ).to receive( :require ).and_return( true )
        allow( Intelligence ).to receive( :const_get ).and_return( nil )
      end

      it 'raises an ArgumentError' do
        expect {
          described_class[ :unknown_adapter ]
        }.to raise_error( ArgumentError, 'An unknown Intelligence adapter unknown_adapter was requested.' )
      end

    end

  end

  describe '.build!' do
    
    it 'builds an instance of the adapter class with given type and attributes' do
      attributes = { key: 'value' }
      adapter_instance = described_class.build!( :test_adapter, attributes )
      expect( adapter_instance ).to be_an_instance_of( Intelligence::TestAdapter::Adapter )
      expect( adapter_instance.instance_variable_get( :@options ) ).to eq( attributes )
    end

    it 'passes a block to the adapter initializer' do
      attributes = { key: 'value' }
      instance_variable_set_in_block = nil
      adapter_instance = described_class.build!( :test_adapter, attributes ) do
        instance_variable_set_in_block = true
      end
      expect( instance_variable_set_in_block ).to be true
      expect( adapter_instance ).to be_an_instance_of( Intelligence::TestAdapter::Adapter )
      expect( adapter_instance.instance_variable_get( :@options ) ).to eq( attributes )
      expect( instance_variable_set_in_block ).to be true
    end

  end

end
