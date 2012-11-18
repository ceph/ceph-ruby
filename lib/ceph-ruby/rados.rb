require "ceph-ruby/rados/lib"
require "ceph-ruby/rados/pool"

module CephRuby
  class Rados
    attr_accessor :state, :cluster

    def self.version
      major = FFI::MemoryPointer.new(:int)
      minor= FFI::MemoryPointer.new(:int)
      extra = FFI::MemoryPointer.new(:int)
      Lib.rados_version(major, minor, extra)
      {
        :major => major.get_int(0),
        :minor => minor.get_int(0),
        :extra => extra.get_int(0),
      }
    end

    def initialize(configuration_path = "/etc/ceph/ceph.conf")
      cluster_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib.rados_create(cluster_p, nil)
      raise "could not initialize rados cluster: #{ret}" if ret < 0
      self.cluster = cluster_p.get_pointer(0)
      self.state = :initialized
      read_configuration_file(configuration_path)

      if block_given?
        connect
        yield self
        shutdown
      end
    end

    def read_configuration_file(path = "/etc/ceph/ceph.conf")
      require_state(:initialized, :connected)
      raise ArgumentError, "path must be a string" unless path.is_a?(String)
      ret = Lib.rados_conf_read_file(cluster, path)
      raise "error reading configuration file '#{path}': #{ret}" if ret < 0
    end

    def shutdown
      return unless cluster
      Lib.rados_shutdown(cluster)
      self.cluster = nil
      self.state = :shutdown
    end

    def connect
      require_state(:initialized)
      ret = Lib.rados_connect(cluster)
      raise "could not connect to cluster: #{ret}" if ret < 0
      self.state = :connected
    end

    def exists?(name)
      require_state(:connected)
      raise ArgumentError, "name must be a string" unless name.is_a?(String)
      ret = Lib.rados_pool_lookup(cluster, name)
      return true if ret >= 0
      return false if ret == -Errno::ENOENT::Errno
      raise "error looking up pool '#{name}': #{ret}"
    end

    def pool(name, &block)
      require_state(:connected)
      raise ArgumentError, "name must be a string" unless name.is_a?(String)
      ioctx_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib.rados_ioctx_create(cluster, name, ioctx_p)
      raise "error creating io context for '#{name}': #{ret}" if ret < 0
      Pool.new(self, name, ioctx_p.get_pointer(0), &block)
    end

    def rbd(name, &block)
      pool(name) do |pool|
        Rbd.new(pool, &block)
      end
    end

    private

    def require_state(*states)
      return if states.include?(state)
      raise "current state must be one of: #{states*", "}"
    end
  end
end
