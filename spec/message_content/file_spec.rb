require 'spec_helper'
require 'uri'
require 'mime/types'

RSpec.describe Intelligence::MessageContent::File do

  describe '#initialize' do
    context 'when attributes include uri and content_type' do
      let( :attributes ) { { uri: 'http://example.com/file.txt', content_type: 'text/plain' } }
      subject { described_class.new( attributes ) }

      it 'sets @uri to the given URI' do
        expect( subject.instance_variable_get( :@uri ) ).to eq( URI( 'http://example.com/file.txt' ) )
      end

      it 'sets @content_type to the given content_type' do
        expect( subject.instance_variable_get( :@content_type ) ).to eq( 'text/plain' )
      end
    end

    context 'when attributes include only uri' do
      let( :attributes ) { { uri: 'http://example.com/file.txt' } }
      subject { described_class.new( attributes ) }

      it 'sets @uri to the given URI' do
        expect( subject.instance_variable_get( :@uri ) ).to eq( URI( 'http://example.com/file.txt' ) )
      end

      it 'leaves @content_type as nil' do
        expect( subject.instance_variable_get( :@content_type ) ).to be_nil
      end
    end

    context 'when attributes include only content_type' do
      let( :attributes ) { { content_type: 'text/plain' } }
      subject { described_class.new( attributes ) }

      it 'leaves @uri as nil' do
        expect( subject.instance_variable_get( :@uri ) ).to be_nil
      end

      it 'sets @content_type to the given content_type' do
        expect( subject.instance_variable_get( :@content_type ) ).to eq( 'text/plain' )
      end
    end

    context 'when attributes are empty' do
      let( :attributes ) { {} }
      subject { described_class.new( attributes ) }

      it 'leaves @uri as nil' do
        expect( subject.instance_variable_get( :@uri ) ).to be_nil
      end

      it 'leaves @content_type as nil' do
        expect( subject.instance_variable_get( :@content_type ) ).to be_nil
      end
    end
  end

  describe '#content_type' do
    context 'when @content_type is already set' do
      let( :attributes ) { { content_type: 'text/plain' } }
      subject { described_class.new( attributes ) }

      it 'returns the existing @content_type' do
        expect( subject.content_type ).to eq( 'text/plain' )
      end
    end

    context 'when @content_type is not set and valid_uri? returns true' do
      context 'and MIME type can be determined from @uri.path' do
        let( :attributes ) { { uri: 'http://example.com/file.txt' } }
        subject { described_class.new( attributes ) }

        it 'sets and returns the MIME type based on @uri.path' do
          expect( subject.content_type ).to eq( 'text/plain' )
        end
      end

      context 'and MIME type cannot be determined from @uri.path' do
        let( :attributes ) { { uri: 'http://example.com/file.unknown' } }
        subject { described_class.new( attributes ) }

        it 'returns nil' do
          expect( subject.content_type ).to be_nil
        end
      end
    end

    context 'when @content_type is not set and valid_uri? returns false' do
      let( :attributes ) { { uri: 'ftp://example.com/file.txt' } }
      subject { described_class.new( attributes ) }

      it 'returns nil' do
        expect( subject.content_type ).to be_nil
      end
    end
  end

  describe '#valid_uri?' do
    context 'with supported scheme and path' do
      let( :attributes ) { { uri: 'https://example.com/file.txt' } }
      subject { described_class.new( attributes ) }

      it 'returns true' do
        expect( subject.valid_uri? ).to be true
      end
    end

    context 'with unsupported scheme' do
      let( :attributes ) { { uri: 'ftp://example.com/file.txt' } }
      subject { described_class.new( attributes ) }

      it 'returns false' do
        expect( subject.valid_uri? ).to be false
      end
    end

    context 'when @uri is nil' do
      let( :attributes ) { {} }
      subject { described_class.new( attributes ) }

      it 'returns false' do
        expect( subject.valid_uri? ).to be false
      end
    end
  end

  describe '#valid?' do
    context 'when valid_uri? returns true and content_type is known' do
      let( :attributes ) { { uri: 'http://example.com/file.txt' } }
      subject { described_class.new( attributes ) }

      it 'returns true' do
        expect( subject.valid? ).to be true
      end
    end

    context 'when valid_uri? returns true but content_type is nil' do
      let( :attributes ) { { uri: 'http://example.com/file.unknown' } }
      subject { described_class.new( attributes ) }

      it 'returns false' do
        expect( subject.valid? ).to be false
      end
    end

    context 'when valid_uri? returns false' do
      let( :attributes ) { { uri: 'ftp://example.com/file.txt' } }
      subject { described_class.new( attributes ) }

      it 'returns false' do
        expect( subject.valid? ).to be false
      end
    end

    context 'when content_type is unknown' do
      let( :attributes ) { { uri: 'http://example.com/file' } }
      subject { described_class.new( attributes ) }

      it 'returns false' do
        expect( subject.valid? ).to be false
      end
    end
  end

  describe '#to_h' do
    let( :attributes ) { { uri: 'http://example.com/file.txt', content_type: 'text/plain' } }
    subject { described_class.new( attributes ) }

    it 'returns the correct hash representation' do
      expect( subject.to_h ).to eq( { type: :file, content_type: 'text/plain', uri: 'http://example.com/file.txt' } )
    end
  end
end

