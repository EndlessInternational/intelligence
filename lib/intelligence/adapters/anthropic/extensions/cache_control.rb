module Intelligence
  module Anthropic
    module Extensions
      module MessageContent
        module CacheControl
          
          def cache_control
            @_cache_control
          end

          def cache_control=( value )
            @_cache_control = case value
                              when true, :ephemeral
                                { type: 'ephemeral' }
                              when false, nil
                                nil
                              when Hash
                                value.transform_keys( &:to_s )
                              else
                                { type: value.to_s }
                              end
          end

          def cache_control_ttl
            @_cache_control && @_cache_control[ 'ttl' ]
          end

          def cache_control_ttl=( value )
            if value.nil?
              @_cache_control&.delete( 'ttl' )
              return
            end

            unless value.is_a?( Integer ) && [ 5, 60 ].include?( value )
              raise ArgumentError, "cache_control_ttl must be 5 or 60 (minutes); received #{value.inspect}"
            end

            # Auto-initialize cache_control if the user sets TTL first
            self.cache_control = :ephemeral if @_cache_control.nil?
            
            # Store the value
            @_cache_control[ 'ttl' ] = value
          end

          def to_h
            hash = super
            hash[ :'anthropic/cache_control' ] = @_cache_control if @_cache_control
            hash
          end

        end
      end
    end
  end
end

Intelligence::MessageContent::Base.prepend( 
  Intelligence::Anthropic::Extensions::MessageContent::CacheControl 
)