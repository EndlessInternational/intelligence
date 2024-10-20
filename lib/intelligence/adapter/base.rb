require_relative 'class_methods'

module Intelligence
  module Adapter
    class Base
      extend AdaptiveConfiguration::Configurable
      extend ClassMethods

      def initialize( options = nil, configuration: nil )
        @options = options ? self.class.configure( options ) : {}
        @options = configuration.merge( @options ) if configuration
      end

    protected 
      attr_reader :options

    end
  end
end

