module Intelligence
  module Adapter 
    module InstanceMethods      

      def build_options( options )
        return {} unless options&.any?
        self.class.builder.build( options )
      end

      def merge_options( options, other_options )
        merged_options = Utilities.deep_dup( options )
        
        other_options.each do | key, value |
          if merged_options[ key].is_a?( Hash ) && value.is_a?( Hash )
            merged_options[ key ] = merge_options( merged_options[ key ], value )
          else
            merged_options[ key ] = value
          end
        end

        merged_options
      end

      def prune_choices( choices )
        choices.map do | original_choice |
          pruned_choice    = original_choice.dup

          original_message = original_choice[ :message ] || { }
          pruned_message   = original_message.dup

          pruned_message[ :contents ] = original_message[ :contents ]&.map do | content |
            { type: content[ :type ] }
          end

          pruned_choice[ :message ] = pruned_message
          pruned_choice
        end
      end

      def merge_choices!( destination, source )
        source.each_with_index do | source_choice, choice_index |
          if destination[ choice_index ]

            destination_choice    = destination[ choice_index ]
            source_message        = source_choice[ :message ] || {}

            # merge choice keys ( everything except :message ) 
            source_choice.each do | key, value |
              next if key == :message
              destination_choice[ key ] = value if value
            end

            destination_message   = destination_choice[ :message ] ||= {}

            # merge message keys ( everything except :contents ) 
            source_message.each do | key, value |
              next if key == :contents
              destination_message[ key ] = value if value
            end

            # merge the :contents arrays 
            source_contents       = Array( source_message[ :contents ] )
            destination_contents  = destination_message[ :contents ] ||= []

            source_contents.each_with_index do | source_content, content_index |
              if destination_content = destination_contents[ content_index ]
                case destination_content[ :type ]
                when :thought, :text 
                  destination_content[ :text ] = 
                    destination_content[ :text ].to_s + source_content[ :text ].to_s
                when :tool_call
                  destination_content[ :tool_parameters ] =
                    destination_content[ :tool_parameters ].to_s + 
                    source_content[ :tool_parameters ].to_s
                when :web_reference
                  # this only appears once so does not need to be merged subsequently
                end
              else
                # the content does not exist in the destination: duplicate the source content
                destination_contents[ content_index ] = Utilities.deep_dup( source_content )
              end
            end
          else
            # choice does not exist yet in the destination: duplicate the source choice
            destination[ choice_index ] = Utilities.deep_dup( source_choice )
          end
        end

        destination
      end

    end
  end
end