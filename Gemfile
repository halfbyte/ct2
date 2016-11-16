source 'https://rubygems.org'

gem 'rails', '4.2.7.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'json'
gem 'jquery-rails'
gem 'haml'
gem 'haml-rails'
gem 'bindata'

gem 'jbuilder'
gem 'unicorn'
gem 'gelf'
gem 'lograge'

gem 'omniauth-soundcloud'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails'
end

group :development do
  gem 'capistrano', :require => false
  gem 'capistrano-unicorn', :require => false
  gem 'rvm-capistrano', :require => false
  gem 'foreman'
end

group :test do
  gem 'rake'
  gem 'capybara'
  gem 'launchy'
  gem 'poltergeist'
  gem 'database_cleaner'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'konacha'
  gem 'sqlite3'
end

group :production do
  gem 'mysql2'
end

gem 'carrierwave'

