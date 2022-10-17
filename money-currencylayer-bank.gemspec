# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'money-currencylayer-bank'
  s.version = '0.7.2'
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.homepage = "http://github.com/phlegx/#{s.name}"
  s.authors = ['Egon Zemmer']
  s.email = 'office@phlegx.com'
  s.description = 'A gem that calculates the exchange rate using published ' \
    'rates from currencylayer.com and apilayer.com. Compatible with the money gem.'
  s.summary = 'A gem that calculates the exchange rate using published rates ' \
    'from currencylayer.com and apilayer.com.'
  s.extra_rdoc_files = %w[README.md]
  s.files = Dir['LICENSE', 'README.md', 'Gemfile', 'lib/**/*.rb',
                'test/**/*']
  s.license = 'MIT'
  s.test_files = Dir.glob('test/*_test.rb')
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.0'
  s.required_rubygems_version = '>=1.3.7'
  s.add_dependency 'json', '>= 1.8'
  s.add_dependency 'monetize', '~> 1.4'
  s.add_dependency 'money', '~> 6.7'
  s.add_development_dependency 'inch', '~>0.8'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'minitest-line', '~> 0.6'
  s.add_development_dependency 'rake', '~>13.0'
  s.add_development_dependency 'rr', '~> 3.1'
  s.add_development_dependency 'rubocop', '~>1.36.0'
  s.add_development_dependency 'timecop', '~>0.9.5'
end
