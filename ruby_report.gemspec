# frozen_string_literal: true

require_relative "lib/ruby_report/version"

Gem::Specification.new do |s|
  s.name        = "ruby_report"
  s.version     = ::RubyReport::VERSION
  s.summary     = "A simple report generator"
  s.description = "A simple report generator"
  s.authors     = ["Alexandr Zavgorodnev"]
  s.email       = "klondaiker@bk.ru"
  s.files       = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]
  s.homepage    = "https://github/klondaiker/ruby_report"
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.7.0"

  s.add_development_dependency "bundler", ">= 1.16"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "rspec", ">= 3.0"
  s.add_development_dependency "pry", ">= 0.14.2"

  s.add_development_dependency "caxlsx", ">= 4.0.0"
  s.add_development_dependency "creek", ">= 2.6.3"
end