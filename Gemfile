source 'https://rubygems.org'

ruby '2.5.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.5'

gem 'clockwork', '~> 2.0'
gem 'delayed_job_active_record', '~> 4.1'
gem 'foreman', '~> 0.63'
gem 'httparty', '~> 0.15'
gem 'paper_trail', '~> 8.1'
gem 'pg', '~> 0.18'
gem 'protobuf', '~> 3.8', require: 'protobuf'
gem 'puma', '~> 3.7'
gem 'rubyzip', '~> 1.2'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara', '~> 2.13'
  gem 'dotenv-rails'
  gem 'selenium-webdriver'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'daemons', '~> 1.2'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
