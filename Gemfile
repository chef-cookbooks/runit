source 'https://rubygems.org'

gem 'rake'

group :lint do
  gem 'foodcritic', '~> 6.0'
  gem 'rubocop', '~> 0.39.0'
end

group :unit do
  gem 'chefspec',   '~> 4.4'
  gem 'chef',       '~> 12.5.0'
end

group :integration do
  gem 'test-kitchen', '~> 1.4'
  gem 'kitchen-vagrant', '~> 0.19'
end

group :librarian do
  gem 'librarian-chef'
end

group :berkshelf do
  gem 'berkshelf', '~> 4.0'
end

group :release do
  gem 'emeril'
end
