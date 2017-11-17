require 'spec_helper'

RSpec.describe CephRuby::Pool do
  let(:cluster)   { CephRuby::Cluster.new(username: 'admin') }
  let(:pool)      { described_class.new(cluster, pool_name) }

  around do |example|
    CephCommands.create_pool(pool_name)
    pool.open

    example.run

    pool.close
    CephCommands.delete_pool(pool_name)
    cluster.close
  end

  describe '#list' do
    let(:pool_name) { 'my-pool-for-testing' }

    context 'no images' do
      it { expect(pool.list).to be_empty }
    end

    context 'one image' do
      let!(:image_name) { 'my-image' }

      before { CephCommands.create_image(pool_name, image_name) }

      it { expect(pool.list).to match_array('my-image') }
    end
  end
end
