source 'https://rubygems.org'

gem 'rails', '3.2.2'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg'

gem 'json'
gem 'jquery-rails'
gem 'haml'
gem 'haml-rails'
gem 'bindata'
gem 'carrierwave'
gem 'jbuilder'

# Gems used only for assets and not required
# in production environments by default.
gem 'unicorn'
gem 'gelf'
# gem 'time_bandits'
gem 'lograge'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano_rsync_with_remote_cache'
  gem 'foreman'
  gem 'thin'
end

group :test do
  gem 'rake'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'launchy'
end

group :development, :test do
  gem 'rspec-rails'
end
