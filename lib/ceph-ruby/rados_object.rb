module CephRuby
  class RadosObject
    attr_accessor :pool, :name

    def initialize(pool, name)
      self.pool = pool
      self.name = name
      if block_given?
        yield(self)
      end
    end

    def exists?
      log("exists?")
      !!stat
    rescue SystemCallError => e
      return false if e.errno == Errno::ENOENT::Errno
      raise e
    end

    def write(offset, data)
      size = data.bytesize
      log("write offset #{offset}, size #{size}")
      ret = Lib::Rados.rados_write(pool.handle, name, data, size, offset)

      raise SystemCallError.new("write of #{size} bytes to '#{name}' at #{offset} failed", -ret) if ret < 0
      raise Errno::EIO.new("wrote only #{ret} of #{size} bytes to '#{name}' at #{offset}") if ret < size
    end

    def read(offset, size)
      log("read offset #{offset}, size #{size}")
      data_p = FFI::MemoryPointer.new(:char, size)
      ret = Lib::Rados.rados_read(pool.handle, name, data_p, size, offset)
      raise SystemCallError.new("read of #{size} bytes from '#{name}' at #{offset} failed", -ret) if ret < 0
      data_p.get_bytes(0, ret)
    end

    def destroy
      log("destroy")
      ret = Lib::Rados.rados_remove(pool.handle, name)
      raise SystemCallError.new("destroy of '#{name}' failed", -ret) if ret < 0
    end

    def resize(size)
      log("resize size #{size}")
      ret = Lib::Rados.rados_trunc(pool.handle, name, size)
      raise SystemCallError.new("resize of '#{name}' to #{size} failed", -ret) if ret < 0
    end

    def stat
      log("stat")
      size_p = FFI::MemoryPointer.new(:uint64)
      mtime_p = FFI::MemoryPointer.new(:uint64)
      ret = Lib::Rados.rados_stat(pool.handle, name, size_p, mtime_p)
      raise SystemCallError.new("stat of '#{name}' failed", -ret) if ret < 0
      {
        :size => size_p.get_uint64(0),
        :mtime => Time.at(mtime_p.get_uint64(0)),
      }
    end

    def size
      stat[:size]
    end

    # helper methods below

    def log(message)
      CephRuby.log("rados object #{pool.name}/#{name} #{message}")
    end
  end
end
