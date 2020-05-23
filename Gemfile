source 'http://rubygems.org'

ruby '2.7.1'

gem 'rails', '~> 6.0', '>= 6.0.2.2'

# Use puma as the webserver
gem 'puma', '4.3.5'
# Use PostgreSQL as the database
gem 'pg', '~> 1.2', '>= 1.2.2'
# Use bcrypt to hash passwords
gem 'bcrypt', '~> 3.1', '>= 3.1.13'
# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1', '>= 2.1.2'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2'

gem 'rails-ujs', '~> 5.1.0.beta1'
# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.3', '>= 4.3.5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9', '>= 2.9.1'
# Use rubyzip for working with zip files
gem 'rubyzip', '~> 2.2'
# Use savon for SOAP
gem 'savon', '~> 2.12'
# Use AWS S3 for image caching
gem 'aws-sdk', '~> 3.0', '>= 3.0.1'


group :development do
  gem 'sql_queries_count'
  gem 'derailed_benchmarks'
  gem 'stackprof'
end

group :development, :test do
  gem 'byebug', '~> 11.1', '>= 11.1.1', platform: :mri
end

group :test do
  gem 'minitest-reporters', '~> 1.4', '>= 1.4.2'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers', '~> 4.2'
  # Use webmock to stub out HTTP API requests
  gem 'webmock', '~> 3.8'
end

group :production do
  gem 'rails_12factor', '~> 0.0.3'
end
