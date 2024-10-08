require 'spec_helper'

RSpec.describe Intelligence::ChatResultChoice, :unit do

  describe '#initialize' do
    context 'when initialized with message, end_reason, and end_sequence' do
      it 'sets the attributes correctly' do
        # prepare test data
        chat_choice_attributes = {
          end_reason: :ended,
          end_sequence: 'Goodbye.',
          message: {
            role: 'assistant',
            contents: [
              { type: :text, text: 'Hello, how can I assist you?' }
            ]
          }
        }

        # create an instance of ChatResultChoice
        chat_result_choice = described_class.new( chat_choice_attributes )

        # check end_reason and end_sequence
        expect( chat_result_choice.end_reason ).to eq( :ended )
        expect( chat_result_choice.end_sequence ).to eq( 'Goodbye.' )

        # build the expected message
        expected_message = Intelligence::Message.new( :assistant )
        expected_message << Intelligence::MessageContent::Text.new( text: 'Hello, how can I assist you?' )

        # compare the messages using to_h
        expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
      end
    end

    context 'when initialized without message' do
      it 'sets message to nil' do
        chat_choice_attributes = {
          end_reason: :filtered,
          end_sequence: 'Inappropriate content'
          # no :message key
        }

        chat_result_choice = described_class.new( chat_choice_attributes )

        expect( chat_result_choice.message ).to be_nil
        expect( chat_result_choice.end_reason ).to eq( :filtered )
        expect( chat_result_choice.end_sequence ).to eq( 'Inappropriate content' )
      end
    end

    context 'message building' do
      it 'builds the message with default role when role is absent' do
        chat_choice_attributes = {
          message: {
            contents: [
              { type: :text, text: 'Default role message' }
            ]
          }
        }

        chat_result_choice = described_class.new( chat_choice_attributes )

        expected_message = Intelligence::Message.new( :assistant )
        expected_message << Intelligence::MessageContent::Text.new( text: 'Default role message' )

        expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
      end

      it 'builds the message with provided role' do
        chat_choice_attributes = {
          message: {
            role: 'user',
            contents: [
              { type: :text, text: 'I need help with my account.' }
            ]
          }
        }

        chat_result_choice = described_class.new( chat_choice_attributes )

        expected_message = Intelligence::Message.new( :user )
        expected_message << Intelligence::MessageContent::Text.new( text: 'I need help with my account.' )

        expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
      end

      it 'handles multiple contents' do
        chat_choice_attributes = {
          message: {
            role: 'assistant',
            contents: [
              { type: :text, text: 'First line of response.' },
              { type: :text, text: 'Second line of response.' }
            ]
          }
        }

        chat_result_choice = described_class.new( chat_choice_attributes )

        expected_message = Intelligence::Message.new( :assistant )
        expected_message << Intelligence::MessageContent::Text.new( text: 'First line of response.' )
        expected_message << Intelligence::MessageContent::Text.new( text: 'Second line of response.' )

        expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
      end
    end
  end

end
