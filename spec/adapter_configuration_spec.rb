require 'spec_helper'

module Intelligence
  module ConfigurationTest
    class Adapter < Intelligence::Adapter::Base
      
      schema do
        api_key String, required: true
        options default: {} do
          timeout Integer
          debug [ TrueClass, FalseClass ], default: false
        end
      end

      attr_reader :api_key, :options

      def initialize( attributes = nil, &block )
        schema = self.class.build_with_schema( attributes, &block )
        @api_key = schema[ :api_key ]
        @options = schema[ :options ] || {}
      end
    end
  end
end

RSpec.describe Intelligence::ConfigurationTest::Adapter, :unit do

  describe '.schema' do
    it 'allows setting and retrieving schema parameters' do
      adapter = described_class.new( api_key: 'test_key' ) do
        options do
          timeout 30
          debug true
        end
      end

      expect( adapter.api_key ).to eq( 'test_key' )
      expect( adapter.options.to_h ).to eq( { timeout: 30, debug: true } )
    end

    it 'uses default values when parameters are not provided' do
      adapter = described_class.new( api_key: 'test_key' )

      expect( adapter.api_key ).to eq( 'test_key' )
      expect( adapter.options.to_h ).to eq( { debug: false } )
    end

    it 'overrides attribute values with block values' do
      adapter = described_class.new( api_key: 'initial_key', options: { timeout: 20 } ) do
        api_key 'overridden_key'
        options do
          timeout 40
        end
      end

      expect( adapter.api_key ).to eq( 'overridden_key' )
      expect( adapter.options.to_h ).to eq( { timeout: 40, debug: false } )
    end

    it 'handles nested parameters parameters' do
      described_class.class_eval do
        schema do
          options do
            debug default: false 
            logging do
              level String, default: 'info'
            end
          end
        end
      end

      adapter = described_class.new( api_key: 'test_key' ) do
        options do
          logging do
            level 'debug'
          end
        end
      end

      expect( adapter.options.to_h ).to eq( { debug: false, logging: { level: 'debug' } } )
    end
  end

end
