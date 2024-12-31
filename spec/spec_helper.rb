require 'rspec'
require 'vcr'
require 'debug'

require 'intelligence'

Dir[ File.join( __dir__, 'support', '**', '*.rb' ) ].each { |f| require f }

RSpec.configure do | config |

  config.formatter = :documentation

  # allows using "describe" instead of "RSpec.describe"
  config.expose_dsl_globally = true

  config.expect_with :rspec do | expectations |
    expectations.syntax = :expect
  end

  config.mock_with :rspec do | mocks |
    mocks.syntax = :expect
  end

  ignore_cassettes = ( config.inclusion_filter.delete( :'ignore-cassettes' ) ? true : false )
  record_cassettes = ( config.inclusion_filter.delete( :'record-cassettes' ) ? true : false )
  config.define_derived_metadata do | metadata |
    metadata[ :ignore_cassettes ] = true if ignore_cassettes
    metadata[ :record_cassettes ] = true if record_cassettes
  end 

end
