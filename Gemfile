source 'http://rubygems.org'

ruby '3.2.0'

gem 'rails', '~> 7.0.3'

# Use puma as the webserver
gem 'puma', '5.6.4'
# Use PostgreSQL as the database
gem 'pg', '~> 1.2', '>= 1.2.2'
# Use bcrypt to hash passwords
gem 'bcrypt', '~> 3.1', '>= 3.1.13'
# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1', '>= 2.1.2'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9', '>= 2.9.1'
# Use rubyzip for working with zip files
gem 'rubyzip', '~> 2.3.0'
# Use AWS S3 for image caching
gem 'aws-sdk-s3', '~> 1.81'

gem 'nokogiri', '>= 1.11.0.rc4'

# Install networking gems for Ruby 3.x on Rails 6.x:
gem 'net-smtp'
gem 'net-imap'
gem 'net-pop'

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

end
