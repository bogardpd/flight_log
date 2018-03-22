source 'http://rubygems.org'

ruby '2.3.1'

gem 'rails', '5.0.0.1'

# Use puma as the webserver
gem 'puma', '3.9.1'
# Use PostgreSQL as the database
gem 'pg' , '0.18.4'
# Use bcrypt to hash passwords
gem 'bcrypt', '3.1.7'
# Use SCSS for stylesheets
gem 'sass-rails', '5.0.6'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '3.0.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '4.2.1'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '2.4.1'
# Use rubyzip for working with zip files
gem 'rubyzip', '~> 1.2'
# Use savon for SOAP
gem 'savon', '~> 2.11', '>= 2.11.1'

# Force loofah to 2.2.1 for security update.
# https://github.com/flavorjones/loofah/issues/144
gem 'loofah', '~> 2.2.1'

group :development do
  gem 'sql_queries_count'
end

group :development, :test do
  gem 'byebug', '9.0.0', platform: :mri
end

group :test do
  gem 'rails-controller-testing', '0.1.1'
  gem 'minitest-reporters',       '1.1.9'
  gem 'guard',                    '2.13.0'
  gem 'guard-minitest',           '2.4.4'
end

group :production do
  gem 'rails_12factor', '0.0.2'
end
