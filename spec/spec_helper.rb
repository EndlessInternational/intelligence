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

  record_cassettes = ( config.inclusion_filter.delete( :'record-cassettes' ) ? true : false )
  config.define_derived_metadata do | metadata |
    metadata[ :record_cassettes ] = true if record_cassettes
  end 

end
