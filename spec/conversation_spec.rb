require 'spec_helper'

RSpec.describe Intelligence::Conversation, :unit do

  describe '#initialize' do
    context 'when given attributes with system_message and messages' do
      it 'initializes system_message and messages correctly' do
        system_message = Intelligence::Message.new( :system )
        messages = [
          Intelligence::Message.new( :user ),
          Intelligence::Message.new( :assistant )
        ]

        attributes = {
          system_message: system_message,
          messages: messages
        }

        conversation = described_class.new( attributes )

        expect( conversation.system_message.to_h ).to eq( system_message.to_h )
        expect( conversation.messages ).to eq( messages )

        expect( conversation.messages ).not_to be( messages )
      end
    end

    context 'when given empty attributes' do
      it 'initializes with default values' do
        conversation = described_class.new

        expect( conversation.system_message ).to be_nil
        expect( conversation.messages ).to eq( [] )
      end
    end
  end

  describe '#has_system_message?' do
    context 'when system_message is present and not empty' do
      it 'returns true' do
        content = Intelligence::MessageContent::Text.new( text: 'System message content' )
        system_message = Intelligence::Message.new( :system )
        system_message.append_content( content )

        conversation = described_class.new( system_message: system_message )

        expect( conversation.has_system_message? ).to be true
      end
    end

    context 'when system_message is nil' do
      it 'returns false' do
        conversation = described_class.new( system_message: nil )

        expect( conversation.has_system_message? ).to be false
      end
    end

    context 'when system_message is empty' do
      it 'returns false' do
        system_message = Intelligence::Message.new( :system )

        conversation = described_class.new( system_message: system_message )

        expect( conversation.has_system_message? ).to be false
      end
    end
  end

  describe '#has_messages?' do
    context 'when messages are present' do
      it 'returns true' do
        message = Intelligence::Message.new( :user )
        conversation = described_class.new( messages: [ message ] )

        expect( conversation.has_messages? ).to be true
      end
    end

    context 'when messages are empty' do
      it 'returns false' do
        conversation = described_class.new( messages: [] )

        expect( conversation.has_messages? ).to be false
      end
    end
  end

  describe '#system_message=' do
    context 'when message is a valid Intelligence::Message with role :system' do
      it 'sets the system_message' do
        message = Intelligence::Message.new( :system )

        conversation = described_class.new
        conversation.system_message = message

        expect( conversation.system_message ).to eq( message )
      end
    end

    context 'when message is not an Intelligence::Message' do
      it 'raises ArgumentError' do
        message = 'Not a message object'  # Invalid message

        conversation = described_class.new

        expect {
          conversation.system_message = message
        }.to raise_error( ArgumentError, /The system message must be a Intelligence::Message./ )
      end
    end

    context "when message's role is not :system" do
      it 'raises ArgumentError' do
        message = Intelligence::Message.new( :user )

        conversation = described_class.new

        expect {
          conversation.system_message = message
        }.to raise_error( ArgumentError, /The system message MUST have a role of 'system'./ )
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash representation of the conversation' do
      system_message = Intelligence::Message.new( :system )
      message1 = Intelligence::Message.new( :user )
      message2 = Intelligence::Message.new( :assistant )

      conversation = described_class.new(
        system_message: system_message,
        messages: [ message1, message2 ]
      )

      expected_hash = {
        system_message: system_message.to_h,
        messages: [ message1.to_h, message2.to_h ],
        tools: []
      }

      expect( conversation.to_h ).to eq( expected_hash )
    end

    it 'handles nil system_message' do
      conversation = described_class.new( system_message: nil )

      expect( conversation.to_h ).to eq( { messages: [], tools: [] } )
    end

    it 'handles empty messages' do
      system_message = Intelligence::Message.new( :system )

      conversation = described_class.new( system_message: system_message )

      expected_hash = {
        system_message: system_message.to_h,
        messages: [],
        tools: []
      }

      expect( conversation.to_h ).to eq( expected_hash )
    end
  end

end


