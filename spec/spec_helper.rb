COOKBOOK_RESOLVERS = {
  'batali' => ['Batali', 'batali/chefspec'],
  'berkshelf' => ['Berksfile', 'chefspec/berkshelf'],
  'librarian' => ['Cheffile', 'chefspec/librarian']
}

require 'chefspec'

if(ENV['COOKBOOK_RESOLVER'])
  require COOKBOOK_RESOLVERS[ENV['COOKBOOK_RESOLVER']]
else
  resolver_lib = COOKBOOK_RESOLVERS.values.detect do |r_file, r_lib|
    File.exists?(File.join(File.dirname(__FILE__), '..', r_file))
  end
  raise "Failed to locate valid cookbook resolver files!" unless resolver_lib
  require resolver_lib.last
end

at_exit { ChefSpec::Coverage.report! }
