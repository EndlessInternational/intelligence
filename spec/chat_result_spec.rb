require 'spec_helper'

RSpec.describe Intelligence::ChatResult, :unit do

  describe '#initialize' do
    context 'when initialized with choices and metrics' do

      let ( :choice_attributes ) do 
        [
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
      end 

      let( :metrics_attributes ) do
        {
          duration: 1500,
          input_tokens: 100,
          output_tokens: 200
        }
      end 

      let( :chat_attributes ) do  
        {
          choices: choice_attributes,
          metrics: metrics_attributes
        }
      end

      it 'sets the attributes correctly' do
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

      let( :choice_attributes ) do 
        [
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
      end

      let( :chat_attributes ) do
        { choices: choice_attributes }
      end

      it 'sets choices and metrics correctly' do
        chat_result = described_class.new( chat_attributes )

        expect( chat_result.choices.length ).to eq( 1 )
        expect( chat_result.choices.first ).to be_an_instance_of( Intelligence::ChatResultChoice )
        expect( chat_result.metrics ).to be_nil
      end
    end

    context 'when initialized without choices' do

      let( :chat_attributes ) do 
        {
          metrics: {
            duration: 1200,
            input_tokens: 80,
            output_tokens: 160
          }
        }
      end 

      it 'sets choices as an empty array' do
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

    context 'when initialize includes arbitrary additional keys' do
      
      let( :choice_attributes ) do
        [
          {
            end_reason: :ended,
            message: {
              role: 'assistant',
              contents: [
                { type: :text, text: 'Payload test.' }
              ]
            }
          }
        ]
      end

      let( :chat_attributes ) do
        {
          id:           'abc-123',
          user:         'alice',
          temperature:  0.85,
          model:        'gpt-4o-mini',
          custom_flag:  true,
          choices:      choice_attributes
          # no metrics key
        }
      end

      let( :chat_result ) { described_class.new( chat_attributes ) }

      it 'exposes an extra key via []' do
        expect( chat_result[ :temperature ] ).to eq( 0.85 )
      end

      it 'responds correctly to key?' do
        expect( chat_result.key?( :model ) ).to be true
        expect( chat_result.key?( :metrics ) ).to be false
      end

      it 'responds correctly to include?' do
        expect( chat_result.include?( :custom_flag ) ).to be true
      end

      it 'enumerates extra attributes with each' do
        expect( chat_result.each.to_h ).to include(
          id:           'abc-123',
          user:         'alice',
          temperature:  0.85,
          model:        'gpt-4o-mini',
          custom_flag:  true
        )
      end

      it 'reports the correct size' do
        expect( chat_result.size ).to eq( 5 )
      end

      it 'is not empty' do
        expect( chat_result ).not_to be_empty
      end
    end

    context 'when no extra keys are provided' do
      let( :chat_result ) { described_class.new( choices: [] ) }

      it 'returns nil for unknown keys with []' do
        expect( chat_result[ :does_not_exist ] ).to be_nil
      end

      it 'returns false from key? and include?' do
        expect( chat_result.key?( :does_not_exist ) ).to be false
        expect( chat_result.include?( :does_not_exist ) ).to be false
      end

      it 'enumerates to an empty hash' do
        expect( chat_result.each.to_h ).to eq( {} )
      end

      it 'reports size as zero' do
        expect( chat_result.size ).to eq( 0 )
      end

      it 'is empty' do
        expect( chat_result ).to be_empty
      end
    end
  end

  describe '#message' do
    context 'when choices are present' do

      let( :choice_attributes ) do
        [
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
      end 

      let( :chat_attributes ) do 
        { choices: choice_attributes }
      end

      it 'returns the message of the first choice' do
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
