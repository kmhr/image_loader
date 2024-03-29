# encoding: utf-8
require File.join(File.dirname(__FILE__), 'lib/tumblr/version')

Gem::Specification.new do |gem|
  gem.add_dependency 'faraday', '>= 0.8'
  gem.add_dependency 'faraday_middleware', '>= 0.8'
  gem.add_dependency 'json'
  gem.add_dependency 'oauth'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'simplecov'
  gem.authors = ["John Bunting"]
  gem.description = %q{A Ruby wrapper for the Tumblr v2 API}
  gem.email = ['codingjester@gmail.com']
  gem.executables = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.files = `git ls-files`.split("\n")
  gem.homepage = "http://github.com/codingjester/tumblr_client"
  gem.name = "tumblr_client"
  gem.require_paths = ["lib"]
  gem.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  gem.summary = %q{Tumblr API wrapper}
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.version = Tumblr::VERSION
end
