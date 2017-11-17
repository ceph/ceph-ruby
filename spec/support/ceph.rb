class CephCommands
  class << self
    def create_pool(pool_name, size = 1)
      `ceph osd pool create #{pool_name} #{size}`
    end

    def delete_pool(pool_name)
      `ceph osd pool delete #{pool_name} #{pool_name} --yes-i-really-really-mean-it`
    end

    def create_image(pool_name, image_name)
      `rbd -p #{pool_name} create #{image_name} --size 128`
    end
  end
end
