source :rubygems

gem 'mongo'
gem 'bson_ext'

group :development, :test do
  gem 'rake'
end

group :development do
  gem 'yard'
  gem 'redcarpet'
end

group :benchmark do
  # for benchmark only
  # requires sudo apt-get install libsasl2-dev
  gem 'memcached'
  gem 'diskcached'
end

group :test do
  gem 'rspec'
  gem 'simplecov', :require => false
end


