source 'http://rubygems.org'

ruby '2.3.1'

gem 'rails', '5.0.0.1'

# Use puma as the webserver
gem 'puma', '3.6.0'
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
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '2.3.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '2.4.1'

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
