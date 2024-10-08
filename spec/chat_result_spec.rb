require 'spec_helper'

RSpec.describe Intelligence::ChatResult, :unit do

  describe '#initialize' do
    context 'when initialized with choices and metrics' do
      it 'sets the attributes correctly' do
        choice_attributes = [
          {
            end_reason: :ended,
            end_sequence: 'Goodbye.',
            message: {
              role: 'assistant',
              contents: [
                { type: :text, text: 'Hello, how can I assist you?' }
              ]
            }
          },
          {
            end_reason: :token_limit_exceeded,
            message: {
              role: 'assistant',
              contents: [
                { type: :text, text: 'This is too long to process.' }
              ]
            }
          }
        ]
        metrics_attributes = {
          duration: 1500,
          input_tokens: 100,
          output_tokens: 200
        }
        chat_attributes = {
          choices: choice_attributes,
          metrics: metrics_attributes
        }

        chat_result = described_class.new( chat_attributes )

        expect( chat_result.choices.length ).to eq( 2 )
        expect( chat_result.choices.first ).to be_an_instance_of( Intelligence::ChatResultChoice )
        # verify choices content
        expected_message = Intelligence::Message.new( :assistant )
        expected_message << Intelligence::MessageContent::Text.new( text: 'Hello, how can I assist you?' )
        expect( chat_result.choices.first.message.to_h ).to eq( expected_message.to_h )
        expect( chat_result.metrics ).to be_an_instance_of( Intelligence::ChatMetrics )
        expect( chat_result.metrics.duration ).to eq( 1500 )
        expect( chat_result.metrics.input_tokens ).to eq( 100 )
        expect( chat_result.metrics.output_tokens ).to eq( 200 )
      end
    end

    context 'when initialized without metrics' do
      it 'sets choices and metrics correctly' do
        choice_attributes = [
          {
            end_reason: :ended,
            message: {
              role: 'assistant',
              contents: [
                { type: :text, text: 'Test message without metrics.' }
              ]
            }
          }
        ]
        chat_attributes = {
          choices: choice_attributes
          # no metrics key
        }

        chat_result = described_class.new( chat_attributes )

        expect( chat_result.choices.length ).to eq( 1 )
        expect( chat_result.choices.first ).to be_an_instance_of( Intelligence::ChatResultChoice )
        expect( chat_result.metrics ).to be_nil
      end
    end

    context 'when initialized without choices' do
      it 'sets choices as an empty array' do
        chat_attributes = {
          metrics: {
            duration: 1200,
            input_tokens: 80,
            output_tokens: 160
          }
          # no choices key
        }

        chat_result = described_class.new( chat_attributes )

        expect( chat_result.choices ).to eq( [] )
        expect( chat_result.metrics ).to be_an_instance_of( Intelligence::ChatMetrics )
      end
    end

    context 'when initialized with empty attributes' do
      it 'sets choices as empty array and metrics as nil' do
        chat_result = described_class.new( {} )

        expect( chat_result.choices ).to eq( [] )
        expect( chat_result.metrics ).to be_nil
      end
    end
  end

  describe '#message' do
    context 'when choices are present' do
      it 'returns the message of the first choice' do
        choice_attributes = [
          {
            end_reason: :ended,
            message: {
              role: 'assistant',
              contents: [
                { type: :text, text: 'First choice message.' }
              ]
            }
          },
          {
            end_reason: :ended,
            message: {
              role: 'assistant',
              contents: [
                { type: :text, text: 'Second choice message.' }
              ]
            }
          }
        ]
        chat_attributes = {
          choices: choice_attributes
        }

        chat_result = described_class.new( chat_attributes )

        message = chat_result.message

        expected_message = Intelligence::Message.new( :assistant )
        expected_message << Intelligence::MessageContent::Text.new( text: 'First choice message.' )

        expect( message.to_h ).to eq( expected_message.to_h )
      end
    end

    context 'when choices are empty' do
      it 'returns nil' do
        chat_result = described_class.new( choices: [] )

        expect( chat_result.message ).to be_nil
      end
    end
  end

end
