module CephRuby
  class Pool
    attr_accessor :cluster, :name, :handle

    def initialize(cluster, name)
      self.cluster = cluster
      self.name = name
      if block_given?
        begin
          yield(self)
        ensure
          close
        end
      end
    end

    def exists?
      log("exists?")
      ret = Lib::Rados.rados_pool_lookup(cluster.handle, name)
      return true if ret >= 0
      return false if ret == -Errno::ENOENT::Errno
      raise SystemCallError.new("lookup of '#{name}' failed", -ret) if ret < 0
    end

    def open
      return if open?
      log("open")
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rados.rados_ioctx_create(cluster.handle, name, handle_p)
      raise SystemCallError.new("creation of io context for '#{name}' failed", -ret) if ret < 0
      self.handle = handle_p.get_pointer(0)
    end

    def close
      return unless open?
      log("close")
      Lib::Rados.rados_ioctx_destroy(handle)
      self.handle = nil
    end

    # We first try to store all of the pools in a `nil` array. If it succeeds, it means we don't have any pools to list.
    # If it fails, `rbd_list` will store the size it needs to display all pools into a variable.
    def list
      log("list")

      pool_size_needed_p = FFI::MemoryPointer.new(:size_t)
      pools_list_p       = nil
      ret                = Lib::Rbd.rbd_list(handle, pools_list_p, pool_size_needed_p)

      return [] if ret.zero? # No pools to show
      raise SystemCallError.new('Query size of list failed') if ret != -Errno::ERANGE::Errno

      pools_list_p = FFI::MemoryPointer.new(:char, pool_size_needed_p.get_int(0))
      ret          = Lib::Rbd.rbd_list(handle, pools_list_p, pool_size_needed_p)

      raise SystemCallError.new('Query list failed') if ret.negative?

      pools_list_p.get_bytes(0, ret).split("\0")
    end

    def rados_object(name, &block)
      ensure_open
      RadosObject.new(self, name, &block)
    end

    def rados_block_device(name, &block)
      ensure_open
      RadosBlockDevice.new(self, name, &block)
    end

    # helper methods below

    def open?
      !!handle
    end

    def ensure_open
      return if open?
      open
    end

    def log(message)
      CephRuby.log("pool #{name} #{message}")
    end
  end
end
