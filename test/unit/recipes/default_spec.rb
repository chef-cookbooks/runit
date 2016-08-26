require 'spec_helper'

require 'spec_helper'

describe 'runit::default' do
  cached(:oel_65_default) do
    ChefSpec::SoloRunner.new(
      platform: 'oracle',
      version: '6.5'
    ) do |node|
      node.set['runit']['version'] = '0.0'
    end.converge(described_recipe)
  end

  it 'adds packagecloud_repo[imeyer/runit]' do
    expect(oel_65_default).to add_packagecloud_repo('imeyer/runit')
  end
end
