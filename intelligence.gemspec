require_relative 'lib/intelligence/version'

Gem::Specification.new do | spec |

  spec.name          = 'intelligence'
  spec.version       = Intelligence::VERSION
  spec.authors       = [ 'Kristoph Cichocki-Romanov' ]
  spec.email         = [ 'rubygems.org@kristoph.net' ]

  spec.summary       = <<~TEXT.gsub( "\n", " " ).strip
    A Ruby gem for seamlessly and uniformly interacting with large languge and vision model (LLM) 
    API's served by numerous services, including those of OpenAI, Anthropic, Google and others. 
  TEXT
  spec.description   = <<~TEXT.gsub( "\n", " " ).strip
    Intelligence is a lightweight yet powerful Ruby gem that allows you to seamlessly and uniformly 
    interact with large language and vision models (LLM) API's of numerous vendors, including 
    OpenAI, Anthropic, Google, Cerebras, Groq, Hyperbolic, Samba Nova and Together AI. It can be 
    trivially expanded to other OpenAI conformant API providers as well as self hosted models.

    Intelligence supports text models in streaming and non-streaming mode, vision models, and 
    tool use.  

    Intelligence has minimal dependencies and does not require the vendors ( often bloated )
    SDK's. 
  TEXT

  spec.license       = 'MIT'
  spec.homepage      = 'https://github.com/EndlessInternational/intelligence'
  spec.metadata = {
    'source_code_uri'   => 'https://github.com/EndlessInternational/intelligence',
    'bug_tracker_uri'   => 'https://github.com/EndlessInternational/intelligence/issues',
#    'documentation_uri' => 'https://github.com/EndlessInternational/intelligence/wiki'
  }

  spec.required_ruby_version = '>= 3.0'
  spec.files         = Dir[ "lib/**/*.rb", "LICENSE", "README.md", "intelligence.gemspec" ]
  spec.require_paths = [ "lib" ]

  spec.add_runtime_dependency 'faraday', '~> 2.7'
  spec.add_runtime_dependency 'dynamicschema', '~> 1.0.0.beta03'
  spec.add_runtime_dependency 'mime-types', '~> 3.6'
  spec.add_runtime_dependency 'json-repair', '~> 0.2'

  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'debug', '~> 1.9'
  spec.add_development_dependency 'vcr', '~> 6.3'

end
