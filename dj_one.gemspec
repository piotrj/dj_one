# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dj_one/version'

Gem::Specification.new do |spec|
  spec.name          = "dj_one"
  spec.version       = DjOne::VERSION
  spec.authors       = ["Piotr Jakubowski"]
  spec.email         = ["piotrj@gmail.com"]

  spec.summary       = "DjOne ensures uniqueness of your DelayedJobs"
  spec.description   = "With DjOne you can get rid of duplicate schedules of particular DelayedJob so that your workers don't have to do the same work twice and you don't need to ensure synchronization between those jobs"
  spec.homepage      = "https://github.com/piotrj/dj_one"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"

  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_dependency   'delayed_job_active_record',  "~> 4.1"
  spec.add_dependency   'railties', '>= 4.0'
end
