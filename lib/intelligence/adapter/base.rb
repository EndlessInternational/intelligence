require_relative 'class_methods'

module Intelligence
  module Adapter
    class Base
      include DynamicSchema::Definable
      extend ClassMethods

      def initialize( options = {}, configuration: nil )
        @options = build_options( options )
        @options = configuration.merge( @options ) if configuration&.any?
      end

    protected 
      attr_reader :options

    private 

      def build_options( options )
        return {} unless options&.any?
        self.class.builder.build( options )
      end

    end
  end
end

