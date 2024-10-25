require_relative 'class_methods'

module Intelligence
  module Adapter
    class Base
      extend DynamicSchema::Definition
      extend ClassMethods

      def initialize( options = nil, configuration: nil )
        @options = options ? self.class.build_with_schema( options ) : {}
        @options = configuration.merge( @options ) if configuration
      end

    protected 
      attr_reader :options

    end
  end
end

