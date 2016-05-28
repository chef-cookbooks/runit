source 'https://rubygems.org'

gem 'rake'

group :lint do
  gem 'foodcritic', '~> 5.0'
  gem 'rubocop', '~> 0.34'
end

group :unit do
  gem 'chefspec',   '~> 4.4'
  gem 'chef',       '~> 12.5.0'
end

group :integration do
  gem 'test-kitchen', '~> 1.4'
  gem 'kitchen-vagrant', '~> 0.19'
end

group :kitchen_docker_cli do
  gem 'kitchen-docker_cli', '= 0.13.0'
end

group :librarian do
  gem 'librarian-chef'
end

group :berkshelf do
  gem 'berkshelf',  '~> 4.0'
end

group :release do
  gem 'emeril'
end
