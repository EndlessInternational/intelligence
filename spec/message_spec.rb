require 'spec_helper'

RSpec.describe Intelligence::Message, :unit do

  describe '#initialize' do
    context 'when given a valid role' do
      it 'sets the role as a symbol' do
        message = described_class.new( :user )
        expect( message.role ).to eq( :user )
      end

      it 'initializes contents as an empty array when no content is provided' do
        message = described_class.new( 'system' )
        expect( message.contents ).to eq( [] )
      end

      it 'adds built content to contents when content_type is provided' do
        content_type = :text
        content_attributes = { text: 'Hello, world!' }
        built_content = double( 'built_content' )
        allow( Intelligence::MessageContent ).to( 
          receive( :build ).with( content_type, content_attributes ).and_return( built_content )
        )

        message = described_class.new( :assistant, content_type, content_attributes )
        expect( message.contents ).to contain_exactly( built_content )
      end
    end

    context 'when given an invalid role' do
      it 'raises an ArgumentError' do
        expect {
          described_class.new( :invalid_role )
        }.to raise_error( ArgumentError, /The role is invalid/ )
      end
    end
  end

  describe '#append_content' do
    it 'adds the content to the contents array' do
      message = described_class.new( :user )
      content = double( 'content' )
      message.append_content( content )
      expect( message.contents ).to include( content )
    end

    it 'does not add nil content' do
      message = described_class.new( :user )
      message.append_content( nil )
      expect( message.contents ).to be_empty
    end

    it 'returns self' do
      message = described_class.new( :user )
      content = double( 'content' )
      expect( message.append_content( content ) ).to eq( message )
    end
  end

  describe '#build_and_append_content' do
    it 'builds content and adds it to contents' do
      message = described_class.new( :user )
      content_type = :text
      content_attributes = { text: 'Sample text' }
      built_content = double( 'built_content' )
      allow( Intelligence::MessageContent ).to receive( :build ).with( content_type, content_attributes ).and_return( built_content )

      message.build_and_append_content( content_type, content_attributes )
      expect( message.contents ).to include( built_content )
    end

    it 'returns self' do
      message = described_class.new( :user )
      content_type = :text
      content_attributes = { text: 'Sample text' }
      expect( message.build_and_append_content( content_type, content_attributes ) ).to eq( message )
    end
  end

  describe '#each_content' do
    it 'iterates over each content in contents' do
      message = described_class.new( :user )
      content1 = double( 'content1' )
      content2 = double( 'content2' )
      message.append_content( content1 )
      message.append_content( content2 )

      contents = []
      message.each_content { | content | contents << content }
      expect( contents ).to eq( [ content1, content2 ] )
    end
  end

  describe '#empty?' do
    it 'returns true when contents are empty' do
      message = described_class.new( :user )
      expect( message.empty? ).to be true
    end

    it 'returns false when contents are not empty' do
      message = described_class.new( :user )
      content = double( 'content' )
      message.append_content( content )
      expect( message.empty? ).to be false
    end
  end

  describe '#valid?' do
    it 'returns true when role is set and all contents are valid' do
      valid_content = double( 'content', valid?: true )
      message = described_class.new( :user )
      message.append_content( valid_content )
      expect( message.valid? ).to be true
    end

    it 'returns false when role is nil' do
      message = described_class.allocate
      message.instance_variable_set( :@role, nil )
      message.instance_variable_set( :@contents, [] )
      expect( message.valid? ).to be false
    end

    it 'returns false when any content is invalid' do
      valid_content = double( 'content', valid?: true )
      invalid_content = double( 'content', valid?: false )
      message = described_class.new( :user )
      message.append_content( valid_content )
      message.append_content( invalid_content )
      expect( message.valid? ).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash representation with role and contents' do
      content1 = double( 'content1', to_h: { type: :text, text: 'Hello' } )
      content2 = double( 'content2', to_h: { type: :image, url: 'http://example.com/image.png' } )
      message = described_class.new( :assistant )
      message.append_content( content1 )
      message.append_content( content2 )

      expected_hash = {
        role: :assistant,
        contents: [
          { type: :text, text: 'Hello' },
          { type: :image, url: 'http://example.com/image.png' }
        ]
      }

      expect( message.to_h ).to eq( expected_hash )
    end
  end

  describe '#<<' do
    it 'aliases append_content method' do
      message = described_class.new( :user )
      content = double( 'content' )
      message << content
      expect( message.contents ).to include( content )
    end
  end

end
