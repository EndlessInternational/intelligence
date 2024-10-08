require 'spec_helper'

RSpec.describe Intelligence::MessageContent::Binary, :unit do
  
  describe '#initialize' do
    it 'sets @content_type and @bytes from attributes when provided' do
      attributes = { content_type: 'image/png', bytes: 'binary_data_here' }
      content = described_class.new( attributes )

      expect( content.content_type ).to eq( 'image/png' )
      expect( content.bytes ).to eq( 'binary_data_here' )
    end

    it 'does not set @content_type and @bytes when not provided' do
      content = described_class.new( {} )

      expect( content.content_type ).to be_nil
      expect( content.bytes ).to be_nil
    end
  end

  describe '#valid?' do
    context 'when content_type and bytes are valid' do
      it 'returns true' do
        attributes = { content_type: 'image/png', bytes: 'binary_data_here' }
        content = described_class.new( attributes )

        expect( content.valid? ).to be true
      end
    end

    context 'when content_type is invalid' do
      it 'returns false' do
        attributes = { content_type: 'invalid/type', bytes: 'binary_data_here' }
        content = described_class.new( attributes )

        expect( content.valid? ).to be false
      end
    end

    context 'when bytes are empty' do
      it 'returns false' do
        attributes = { content_type: 'image/png', bytes: '' }
        content = described_class.new( attributes )

        expect( content.valid? ).to be false
      end
    end

    context 'when bytes is nil' do
      it 'returns false' do
        attributes = { content_type: 'image/png', bytes: nil }
        content = described_class.new( attributes )

        expect( content.valid? ).to be false
      end
    end

    context 'when content_type is missing' do
      it 'returns false' do
        attributes = { bytes: 'binary_data_here' }
        content = described_class.new( attributes )

        expect( content.valid? ).to be false
      end
    end

    context 'when bytes is missing' do
      it 'returns false' do
        attributes = { content_type: 'image/png' }
        content = described_class.new( attributes )
        expect( content.valid? ).to be false
      end
    end
  end

  describe '#image?' do
    context 'when content_type is an image type' do
      it 'returns true' do
        attributes = { content_type: 'image/jpeg', bytes: 'binary_data_here' }
        content = described_class.new( attributes )

        expect( content.image? ).to be true
      end
    end

    context 'when content_type is not an image type' do
      it 'returns false' do
        attributes = { content_type: 'application/pdf', bytes: 'binary_data_here' }
        content = described_class.new( attributes )

        expect( content.image? ).to be false
      end
    end

    context 'when content_type is invalid' do
      it 'returns false' do
        attributes = { content_type: 'invalid/type', bytes: 'binary_data_here' }
        content = described_class.new( attributes )

        expect( content.image? ).to be false
      end
    end

    context 'when content_type is missing' do
      it 'returns false' do
        attributes = { bytes: 'binary_data_here' }
        content = described_class.new( attributes )
        
        expect( content.image? ).to be false
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash representation with type, content_type, and bytes' do
      attributes = { content_type: 'application/octet-stream', bytes: 'test_bytes' }
      content = described_class.new( attributes )
      expected_hash = { type: :binary, content_type: 'application/octet-stream', bytes: 'test_bytes' }

      expect( content.to_h ).to eq( expected_hash )
    end

    it 'includes type :binary even when content_type and bytes are nil' do
      content = described_class.new( {} )
      expected_hash = { type: :binary, content_type: nil, bytes: nil }

      expect( content.to_h ).to eq( expected_hash )
    end
  end

end
