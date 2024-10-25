require 'spec_helper'

RSpec.describe Intelligence::Message, :unit do

  let( :text_content ) {
    Intelligence::MessageContent.build!( :text, text: 'text' )
  }

  let( :binary_content ) {
    Intelligence::MessageContent.build!( :binary, content_type: 'image/jpg', bytes: '...bytes...' )
  }

  describe '.build' do 
    context 'when given no block and no attributes' do 
      it 'raises an ArgumentError' do 
        expect { described_class.build! }.to( 
          raise_error( 
            DynamicSchema::RequiredOptionError, 
            /The attribute 'role' is required/
          )
        )
      end
    end
    
    context 'when given no block and attributes that contain a role' do 
      it 'initializes with a role as a symbol' do
        message = described_class.build!( role: :system )
        expect( message.role ).to eq( :system )
      end
    end
  
    context 'when given a role and multiple content items of different types' do 
      it 'initializes with a role and mutliple content items' do 
        message = described_class.build! do 
          role :user 
          content text: 'text 0'
          content do  
            type :binary 
            content_type 'image/png'
            bytes '..bytes..'
          end
        end

        expect( message.role ).to eq( :user )
        expect( message.contents.size ).to eq( 2 )
        expect( message.contents[ 0 ] ).to be_a( Intelligence::MessageContent::Text )
        expect( message.contents[ 1 ] ).to be_a( Intelligence::MessageContent::Binary )
      end
    end
  end

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
    end

    context 'when given an invalid role' do
      it 'raises an ArgumentError' do
        expect { described_class.new( :invalid_role ) }.to( 
          raise_error( ArgumentError, /The role is invalid/ )
        )
      end
    end
  end

  describe '#text' do  
    context 'when a message is initialized with a role and no content' do 
      it 'returns an empty string' do
        message = described_class.new( :assistant )
        expect( message.text ).to eq( '' )
      end
    end

    context 'when a message is initialized with a role and text content' do 
      it 'returns the text of that text content' do
        message = described_class.new( :user )
        message.append_content( text_content )
        expect( message.text ).to eq( 'text' )
      end
    end

    context 'when a message is initialized with a role and binary content' do 
      it 'returns an empty string' do
        message = described_class.new( :user )
        message.append_content( binary_content )
        expect( message.text ).to eq( '' )
      end
    end

    context 'when a message is initialized with a role and multiple instances of text content' do 
      it 'returns the text with the text content joined by a newline' do
        message = described_class.new( :user )
        message.append_content( text_content )
        message.append_content( text_content )
        expect( message.text ).to eq( "text\ntext" )
      end
    end
    
    context 'when a message is initialized with a role and text, binary, text content interleaved' do 
      it 'returns the text with the text content joined by a newline' do
        message = described_class.new( :user )
        message.append_content( text_content )
        message.append_content( binary_content )
        message.append_content( text_content )
        expect( message.text ).to eq( "text\ntext" )
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
