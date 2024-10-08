require 'spec_helper'

RSpec.describe Intelligence::ErrorResult, :unit do

  describe '#initialize' do
    context 'when initialized with all attributes' do
      it 'sets the attributes correctly' do
        error_attributes = {
          error_type: :invalid_request_error,
          error: 'Invalid request format',
          error_description: 'There was an issue with the format or content of your request.'
        }

        error_result = described_class.new( error_attributes )

        expect( error_result.error_type ).to eq( :invalid_request_error )
        expect( error_result.error ).to eq( 'Invalid request format' )
        expect( error_result.error_description ).to eq( 'There was an issue with the format or content of your request.' )
      end
    end

    context 'when initialized with some attributes missing' do
      it 'sets only the provided attributes' do
        error_attributes = {
          error_type: :authentication_error,
          error_description: "There's an issue with your API key."
          # error is missing
        }

        error_result = described_class.new( error_attributes )

        expect( error_result.error_type ).to eq( :authentication_error )
        expect( error_result.error ).to be_nil
        expect( error_result.error_description ).to eq( "There's an issue with your API key." )
      end
    end

    context 'when initialized with unknown attributes' do
      it 'ignores unknown attributes' do
        error_attributes = {
          error_type: :unknown_error,
          error: 'An unexpected error occurred',
          error_description: 'An unknown error occurred.',
          unknown_attribute: 'should be ignored'
        }

        error_result = described_class.new( error_attributes )

        expect( error_result.error_type ).to eq( :unknown_error )
        expect( error_result.error ).to eq( 'An unexpected error occurred' )
        expect( error_result.error_description ).to eq( 'An unknown error occurred.' )
        expect( error_result.instance_variable_defined?( :@unknown_attribute ) ).to be false
      end
    end

    context 'when initialized with empty attributes' do
      it 'sets all attributes to nil' do
        error_result = described_class.new( {} )

        expect( error_result.error_type ).to be_nil
        expect( error_result.error ).to be_nil
        expect( error_result.error_description ).to be_nil
      end
    end
  end

  describe '#empty?' do
    context 'when all attributes are nil' do
      it 'returns true' do
        error_result = described_class.new( {} )

        expect( error_result.empty? ).to be true
      end
    end

    context 'when any attribute is set' do
      it 'returns false if error_type is set' do
        error_result = described_class.new( error_type: :api_error )

        expect( error_result.empty? ).to be false
      end

      it 'returns false if error is set' do
        error_result = described_class.new( error: 'Some error message' )

        expect( error_result.empty? ).to be false
      end

      it 'returns false if error_description is set' do
        error_result = described_class.new( error_description: 'An error occurred' )

        expect( error_result.empty? ).to be false
      end
    end
  end

end

