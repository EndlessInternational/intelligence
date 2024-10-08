require 'spec_helper'

RSpec.describe Intelligence::ChatMetrics, :unit do

  describe '#initialize' do
    context 'when initialized with all attributes' do
      it 'sets the attributes correctly' do
        attributes = {
          duration: 1500,
          input_tokens: 100,
          output_tokens: 200
        }

        chat_metrics = described_class.new( attributes )

        expect( chat_metrics.duration ).to eq( 1500 )
        expect( chat_metrics.input_tokens ).to eq( 100 )
        expect( chat_metrics.output_tokens ).to eq( 200 )
      end
    end

    context 'when initialized with some attributes missing' do
      it 'sets only the provided attributes' do
        attributes = {
          duration: 1500,
          input_tokens: 100
          # output_tokens is missing
        }

        chat_metrics = described_class.new( attributes )

        expect( chat_metrics.duration ).to eq( 1500 )
        expect( chat_metrics.input_tokens ).to eq( 100 )
        expect( chat_metrics.output_tokens ).to be_nil
      end
    end

    context 'when initialized with empty attributes' do
      it 'does not set any attributes' do
        chat_metrics = described_class.new( {} )

        expect( chat_metrics.duration ).to be_nil
        expect( chat_metrics.input_tokens ).to be_nil
        expect( chat_metrics.output_tokens ).to be_nil
      end
    end

    context 'when initialized with attributes that do not correspond to instance variables' do
      it 'ignores unknown attributes' do
        attributes = {
          duration: 1500,
          input_tokens: 100,
          output_tokens: 200,
          unknown_attribute: 'ignored'
        }

        chat_metrics = described_class.new( attributes )

        expect( chat_metrics.duration ).to eq( 1500 )
        expect( chat_metrics.input_tokens ).to eq( 100 )
        expect( chat_metrics.output_tokens ).to eq( 200 )
        expect( chat_metrics.instance_variable_defined?( :@unknown_attribute ) ).to be false
      end
    end
  end

  describe '#total_tokens' do
    context 'when input_tokens and output_tokens are set' do
      it 'returns the sum of input_tokens and output_tokens' do
        chat_metrics = described_class.new(
          input_tokens: 100,
          output_tokens: 200
        )

        expect( chat_metrics.total_tokens ).to eq( 300 )
      end

      it 'memoizes the total_tokens value' do
        chat_metrics = described_class.new(
          input_tokens: 100,
          output_tokens: 200
        )

        # first call to total_tokens computes and sets @total_tokens
        expect( chat_metrics.total_tokens ).to eq( 300 )
        # change input_tokens and output_tokens
        chat_metrics.instance_variable_set( :@input_tokens, 150 )
        chat_metrics.instance_variable_set( :@output_tokens, 250 )
        # since @total_tokens is memoized, it should not change
        expect( chat_metrics.total_tokens ).to eq( 300 )
      end
    end

    context 'when input_tokens or output_tokens is nil' do
      it 'returns nil if input_tokens is nil' do
        chat_metrics = described_class.new(
          input_tokens: nil,
          output_tokens: 200
        )

        expect( chat_metrics.total_tokens ).to be_nil
      end

      it 'returns nil if output_tokens is nil' do
        chat_metrics = described_class.new(
          input_tokens: 100,
          output_tokens: nil
        )

        expect( chat_metrics.total_tokens ).to be_nil
      end

      it 'returns nil if both input_tokens and output_tokens are nil' do
        chat_metrics = described_class.new(
          input_tokens: nil,
          output_tokens: nil
        )

        expect( chat_metrics.total_tokens ).to be_nil
      end
    end

  end
end
