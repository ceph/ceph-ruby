module CephRuby
  class Cluster
    attr_accessor :handle

    # Creates a connection to a given ceph Cluster
    # Takes optional paramaters config_path, and an options hash
    # config_path string - path to ceph configuration file
    # options:
    #  :cluster - cluster name (default: ceph)
    #  :user    - cephx key file and user to use (default: client.admin)
    def initialize(config_path = '/etc/ceph/ceph.conf', options = {})
      cluster = options.fetch(:cluster, 'ceph')
      user = options.fetch(:user, 'client.admin')
      log("init lib rados #{Lib::Rados.version_string}, lib rbd #{Lib::Rbd.version_string}")

      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rados.rados_create2(handle_p, cluster, user, 0)
      raise SystemCallError.new('open of cluster failed', -ret) if ret < 0
      self.handle = handle_p.get_pointer(0)

      setup_using_file(config_path)

      connect

      if block_given?
        yield(self)
        shutdown
      end
    end

    def shutdown
      return unless handle
      log("shutdown")
      Lib::Rados.rados_shutdown(handle)
      self.handle = nil
    end

    def pool(name, &block)
      Pool.new(self, name, &block)
    end

    # helper methods below

    def connect
      log("connect")
      ret = Lib::Rados.rados_connect(handle)
      raise SystemCallError.new("connect to cluster failed", -ret) if ret < 0
    end

    def setup_using_file(path)
      log("setup_using_file #{path}")
      ret = Lib::Rados.rados_conf_read_file(handle, path)
      raise SystemCallError.new("setup of cluster from config file '#{path}' failed", -ret) if ret < 0
    end

    def log(message)
      CephRuby.log("cluster #{message}")
    end
  end
end
