source "https://rubygems.org"

ruby "3.2.2"                            # Specifies the required Ruby version

gem "rails", "~> 7.1.5", ">= 7.1.5.1"   # The core Rails framework
gem "sprockets-rails"                   # Asset compilation pipeline (though often replaced by others in modern Rails)
gem "mysql2", "~> 0.5"                  # The adapter to connect Rails to your MySQL database
gem "puma", ">= 5.0"                    # The default web server for Rails
gem "importmap-rails"                   # For managing JavaScript dependencies without Node.js/npm
gem "turbo-rails"                       # For faster page loads and persistent elements (part of Hotwire)
gem "stimulus-rails"                    # A modest JavaScript framework (part of Hotwire)
gem "jbuilder"                          # For building JSON responses (useful for APIs)
gem "bootsnap", require: false          # Speeds up boot time

group :development, :test do
  gem "byebug"                          # Ruby debugger
  gem "dotenv-rails"                    # For loading environment variables from a .env file
end

group :development do
  gem "web-console"                     # Rails development console in the browser
end

group :test do
  gem "rspec-rails"                     # A popular testing framework (alternative to Rails' default Minitest)
end
