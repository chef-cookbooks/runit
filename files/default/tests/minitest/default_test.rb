describe_recipe 'runit::default' do
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources
  describe "packages" do
    it 'has been installed' do
      package("runit").must_be_installed
    end
  end
end
