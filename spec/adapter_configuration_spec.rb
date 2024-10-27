require 'spec_helper'

module Intelligence
  module ConfigurationTest
    class Adapter < Intelligence::Adapter::Base
      
      schema do
        api_key String, required: true
        settings default: {} do
          timeout Integer
          debug [ TrueClass, FalseClass ], default: false
          logging do
            level String, default: 'info'
          end
        end
      end

      attr_reader :api_key, :settings

      def initialize( attributes = nil, configuration: nil )
        super( attributes, configuration: configuration )
        @api_key = self.options[ :api_key ]
        @settings = self.options[ :settings ] 
      end
    end
  end
end

RSpec.describe Intelligence::ConfigurationTest::Adapter, :unit do

  describe '.schema' do
    it 'allows setting and retrieving schema parameters' do
      adapter = described_class.build( api_key: 'test_key' ) do
        settings do
          timeout 30
          debug true
        end
      end

      expect( adapter.api_key ).to eq( 'test_key' )
      expect( adapter.settings.to_h ).to eq( { timeout: 30, debug: true } )
    end

    it 'uses default values when parameters are not provided' do
      adapter = described_class.build( api_key: 'test_key' )

      expect( adapter.api_key ).to eq( 'test_key' )
      expect( adapter.settings ).to eq( { debug: false } )
    end

    it 'overrides attribute values with block values' do
      adapter = described_class.build( api_key: 'initial_key', options: { timeout: 20 } ) do
        api_key 'overridden_key'
        settings do
          timeout 40
        end
      end

      expect( adapter.api_key ).to eq( 'overridden_key' )
      expect( adapter.settings ).to eq( { timeout: 40, debug: false } )
    end

    it 'handles nested parameters parameters' do
      adapter = described_class.build( api_key: 'test_key' ) do
        settings do
          logging do
            level 'debug'
          end
        end
      end

      expect( adapter.settings.to_h ).to eq( { debug: false, logging: { level: 'debug' } } )
    end
  end

end
