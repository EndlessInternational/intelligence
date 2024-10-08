module FixtureHelperMethods
  def fixture_file_path( file_name )
    File.expand_path( File.join( '..', 'fixtures', 'files', file_name ), __dir__ )
  end
end

RSpec.configure do | config |
  config.include FixtureHelperMethods
end
