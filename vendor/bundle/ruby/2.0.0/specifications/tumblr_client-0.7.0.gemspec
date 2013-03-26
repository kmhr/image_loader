# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "tumblr_client"
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Bunting"]
  s.date = "2013-02-05"
  s.description = "A Ruby wrapper for the Tumblr v2 API"
  s.email = ["codingjester@gmail.com"]
  s.executables = ["tumblr"]
  s.files = ["bin/tumblr"]
  s.homepage = "http://github.com/codingjester/tumblr_client"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.0"
  s.summary = "Tumblr API wrapper"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<faraday>, [">= 0.8"])
      s.add_runtime_dependency(%q<faraday_middleware>, [">= 0.8"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<oauth>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<faraday>, [">= 0.8"])
      s.add_dependency(%q<faraday_middleware>, [">= 0.8"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<oauth>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<faraday>, [">= 0.8"])
    s.add_dependency(%q<faraday_middleware>, [">= 0.8"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<oauth>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end
