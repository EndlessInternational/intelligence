require_relative 'chat_request_methods'
require_relative 'chat_response_methods'

module Intelligence
  module XAi 

    class Adapter < Generic::Adapter

      DEFAULT_BASE_URI            = "https://api.x.ai/v1"

      schema do 
      
        base_uri                  String, default: DEFAULT_BASE_URI
        key                       String 

        chat_options do 
          model                   String
          frequency_penalty       Float, in: -2..2
          logit_bias              Hash 
          logprobs                [ TrueClass, FalseClass ]
          max_tokens              Integer 
          n                       Integer
          presence_penalty        Float, in: -2..2
          reasoning_effort        Symbol, in: [ :low, :high ]
          response_format 
          seed                    Integer 
          stop                    String, array: true
          stream                  [ TrueClass, FalseClass ]
          stream_options 
          temperature             Float, in: 0..2

          tool                    array: true, as: :tools, &Tool.schema 
          tool_choice 

          top_logprobs            Integer, in: 0..20
          top_p                   Float 
          
          user                    String 

          abilities do 
            web_search            as: :search_parameters do 
              mode                Symbol, in: [ :auto, :on, :off ], default: :auto
              return_citations    [ TrueClass, FalseClass ]
              from_date           String 
              to_date             String
              max_search_results  Integer, in: (1..)
              sources             array: true do 
                type              Symbol, in: [ :web, :x, :news, :rss ], required: true 
                # web only
                allowed_websites  String, array: true
                # web and news
                excluded_websites String, array: true
                safe_search       [ TrueClass, FalseClass ]
                # x
                x_handles         String, array: true
                # rss 
                links             String, array: true
              end
            end 
          end
        
        end
      end

      include ChatRequestMethods 
      include ChatResponseMethods 

      def chat_result_error_attributes( response )
        error_type, error_description = to_error_response( response.status )
        error = error_type 

        parsed_body = JSON.parse( response.body, symbolize_names: true ) rescue nil 
        if parsed_body && parsed_body.respond_to?( :[] )
          error = parsed_body[ :code ] || error_type 
          error_description = parsed_body[ :error ] || error_description 
        end 

        { error_type: error_type.to_s, error: error.to_s, error_description: error_description }
      end

      alias_method :stream_result_error_attributes, :chat_result_error_attributes

    end

  end
end
