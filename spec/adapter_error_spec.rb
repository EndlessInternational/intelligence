require 'spec_helper'

RSpec.describe Intelligence::AdapterError, :unit do

  describe '#initialize' do
    it 'sets the error message correctly based on adapter_type and text' do
      error = described_class.new( :some_adapter, 'failed to initialize' )
      expect( error.message ).to eq( 'The SomeAdapter failed to initialize.' )
    end

    it 'formats adapter_type with underscores into camel case' do
      error = described_class.new( :some_adapter_type, 'encountered an error' )
      expect( error.message ).to eq( 'The SomeAdapterType encountered an error.' )
    end

    it 'handles adapter_type as a string' do
      error = described_class.new( 'another_adapter', 'is not available' )
      expect( error.message ).to eq( 'The AnotherAdapter is not available.' )
    end

    it 'handles text with complex sentences' do
      error = described_class.new( :complex_adapter, 'could not process the request due to unexpected input' )
      expect( error.message ).to eq( 'The ComplexAdapter could not process the request due to unexpected input.' )
    end
  end

end
