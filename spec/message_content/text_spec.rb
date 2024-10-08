require 'spec_helper'

RSpec.describe Intelligence::MessageContent::Text, :unit do

  describe '#initialize' do
    it 'sets @text from attributes when provided' do
      attributes = { text: 'Hello, world!' }
      content = described_class.new( attributes )

      expect( content.text ).to eq( 'Hello, world!' )
    end

    it 'does not set @text when text is not provided' do
      content = described_class.new( {} )

      expect( content.text ).to be_nil
    end
  end

  describe '#valid?' do
    context 'when text is provided and not empty' do
      it 'returns true' do
        attributes = { text: 'Sample text' }
        content = described_class.new( attributes )

        expect( content.valid? ).to be true
      end
    end

    context 'when text is nil' do
      it 'returns false' do
        attributes = { text: nil }
        content = described_class.new( attributes )

        expect( content.valid? ).to be false
      end
    end

    context 'when text is empty' do
      it 'returns false' do
        attributes = { text: '' }
        content = described_class.new( attributes )

        expect( content.valid? ).to be false
      end
    end

    context 'when text does not respond to #empty?' do
      it 'returns false' do
        attributes = { text: 12345 }  
        content = described_class.new( attributes )

        expect( content.valid? ).to be false
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash representation with type and text' do
      attributes = { text: 'Test content' }
      content = described_class.new( attributes )
      expected_hash = { type: :text, text: 'Test content' }

      expect( content.to_h ).to eq( expected_hash )
    end

    it 'includes type :text even when text is nil' do
      content = described_class.new( {} )
      expected_hash = { type: :text, text: nil }

      expect( content.to_h ).to eq( expected_hash )
    end
  end

end
