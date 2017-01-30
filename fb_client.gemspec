# encoding:utf-8

Gem::Specification.new do |s|
  s.name        = 'fb_client'
  s.version     = '0.3.5'
  s.date        = '2015-05-13'
  s.summary     = "FB Tokener for Rasi"
  s.description = "Fetch data from FB Graph API"
  s.authors     = ["Tomas Hrabal"]
  s.email       = 'hrabal.tomas@gmail.com'
  s.files       = [
    "lib/fb_client.rb",
    "lib/fb_client/token.rb",
    "lib/fb_client/fetch.rb",
    "lib/fb_client/request.rb",
  ]
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.homepage    =
    'http://github.com'
  s.license       = 'MIT'

  s.add_dependency 'typhoeus'
  s.add_dependency 'oj', '~> 2.11'
  s.add_development_dependency 'rake', '~> 11.0 '
  s.add_development_dependency 'bundler', '~> 1.11'
  s.add_development_dependency "test-unit"
  s.add_development_dependency "rspec", "~> 3.2"
  s.add_development_dependency "pry"
end
