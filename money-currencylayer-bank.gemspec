# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'money-currencylayer-bank'
  s.version = '0.5.6'
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.homepage = "http://github.com/phlegx/#{s.name}"
  s.authors = ['Egon Zemmer']
  s.email = 'office@phlegx.com'
  s.description = 'A gem that calculates the exchange rate using published ' \
    'rates from currencylayer.com. Compatible with the money gem.'
  s.summary = 'A gem that calculates the exchange rate using published rates ' \
    'from currencylayer.com.'
  s.extra_rdoc_files = %w[README.md]
  s.files = Dir['LICENSE', 'README.md', 'Gemfile', 'lib/**/*.rb',
                'test/**/*']
  s.license = 'MIT'
  s.test_files = Dir.glob('test/*_test.rb')
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.3'
  s.rubygems_version = '1.3.7'
  s.add_dependency 'money', '~> 6.7'
  s.add_dependency 'monetize', '~> 1.4'
  s.add_dependency 'json', '>= 1.8'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'minitest-line', '~> 0.6'
  s.add_development_dependency 'rr', '~> 1.1'
  s.add_development_dependency 'rake', '~>12.0'
  s.add_development_dependency 'timecop', '~>0.8.1'
  s.add_development_dependency 'rubocop', '~>0.49.1'
  s.add_development_dependency 'inch', '~>0.7.1'
end
