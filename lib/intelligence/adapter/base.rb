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

      def merge_options( options, other_options )
        merged_options = options.dup

        other_options.each do | key, value |
          if merged_options[ key].is_a?( Hash ) && value.is_a?( Hash )
            merged_options[ key ] = merge_options( merged_options[ key ], value )
          else
            merged_options[ key ] = value
          end
        end

        merged_options
      end

    end
  end
end

