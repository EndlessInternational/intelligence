require_relative 'class_methods'
require_relative 'instance_methods'

module Intelligence
  module Adapter
    class Base
      include DynamicSchema::Definable
      extend ClassMethods

      def initialize( options = {}, configuration: nil )
        @options = build_options( options )
        @options = configuration.merge( @options ) if configuration&.any?
      end

      include InstanceMethods

    protected 
      attr_reader :options

    end
  end
end

