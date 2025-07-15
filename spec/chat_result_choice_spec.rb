require 'spec_helper'

RSpec.describe Intelligence::ChatResultChoice, :unit do

  describe '#initialize' do
    context 'when initialized with message, end_reason, and end_sequence' do
      let( :chat_choice_attributes ) do
        {
          end_reason:   :ended,
          end_sequence: 'Goodbye.',
          message: {
            role:     'assistant',
            contents: [
              { type: :text, text: 'Hello, how can I assist you?' }
            ]
          }
        }
      end

      let( :chat_result_choice ) { described_class.new( chat_choice_attributes ) }

      it 'sets the attributes correctly' do
        expect( chat_result_choice.end_reason   ).to eq( :ended )
        expect( chat_result_choice.end_sequence ).to eq( 'Goodbye.' )

        expected_message = Intelligence::Message.new( :assistant )
        expected_message << Intelligence::MessageContent::Text.new( text: 'Hello, how can I assist you?' )

        expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
      end
    end

    context 'when initialized without message' do
      let( :chat_choice_attributes ) do
        {
          end_reason:   :filtered,
          end_sequence: 'Inappropriate content'
        }
      end

      let( :chat_result_choice ) { described_class.new( chat_choice_attributes ) }

      it 'sets message to nil' do
        expect( chat_result_choice.message      ).to be_nil
        expect( chat_result_choice.end_reason   ).to eq( :filtered )
        expect( chat_result_choice.end_sequence ).to eq( 'Inappropriate content' )
      end
    end

    describe 'message building' do
      context 'when role is absent' do
        let( :chat_choice_attributes ) do
          {
            message: {
              contents: [
                { type: :text, text: 'Default role message' }
              ]
            }
          }
        end

        let( :chat_result_choice ) { described_class.new( chat_choice_attributes ) }

        it 'defaults role to :assistant' do
          expected_message = Intelligence::Message.new( :assistant )
          expected_message << Intelligence::MessageContent::Text.new( text: 'Default role message' )

          expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
        end
      end

      context 'when role is provided' do
        let( :chat_choice_attributes ) do
          {
            message: {
              role:     'user',
              contents: [
                { type: :text, text: 'I need help with my account.' }
              ]
            }
          }
        end

        let( :chat_result_choice ) { described_class.new( chat_choice_attributes ) }

        it 'uses the provided role' do
          expected_message = Intelligence::Message.new( :user )
          expected_message << Intelligence::MessageContent::Text.new( text: 'I need help with my account.' )

          expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
        end
      end

      context 'when multiple contents are present' do
        let( :chat_choice_attributes ) do
          {
            message: {
              role:     'assistant',
              contents: [
                { type: :text, text: 'First line of response.' },
                { type: :text, text: 'Second line of response.' }
              ]
            }
          }
        end

        let( :chat_result_choice ) { described_class.new( chat_choice_attributes ) }

        it 'adds all contents to the message' do
          expected_message = Intelligence::Message.new( :assistant )
          expected_message << Intelligence::MessageContent::Text.new( text: 'First line of response.' )
          expected_message << Intelligence::MessageContent::Text.new( text: 'Second line of response.' )

          expect( chat_result_choice.message.to_h ).to eq( expected_message.to_h )
        end
      end
    end  
  end
  
end