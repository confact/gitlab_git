source 'https://rubygems.org'

gemspec

group :development do
  gem 'rubocop', '~> 0.43.0'
  gem 'rubocop-rspec', '~> 1.8.0'
  gem 'rspec', '~> 3.5.0'
  gem 'pry'
  gem 'rake'
end

group :test do
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'bundler-audit', '~> 0.5.0', require: false
  gem "appraisal"
end
