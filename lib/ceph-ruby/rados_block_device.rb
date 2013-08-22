module CephRuby
  class RadosBlockDevice
    attr_accessor :pool, :name, :handle

    delegate :cluster, :to => :pool

    def initialize(pool, name)
      self.pool = pool
      self.name = name

      if block_given?
        yield(self)
        close
      end
    end

    def exists?
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rbd.rbd_open(pool.handle, name, handle_p, nil)
      case ret
      when 0
        handle = handle_p.get_pointer(0)
        Lib::Rbd.rbd_close(handle)
        true
      when -Errno::ENOENT::Errno
        false
      else
        raise SystemCallError.new("open of '#{name}' failed", -ret) if ret < 0
      end
    end

    def create(size, features = 0, order = 26)
      order_p = FFI::MemoryPointer.new(:int)
      order_p.put_int(0, order)
      ret = Lib::Rbd.rbd_create2(pool.handle, name, size, features, order_p)
      raise SystemCallError.new("creation of '#{name}' failed", -ret) if ret < 0
    end

    def open
      return if open?
      handle_p = FFI::MemoryPointer.new(:pointer)
      ret = Lib::Rbd.rbd_open(pool.handle, name, handle_p, nil)
      raise SystemCallError.new("open of '#{name}' failed", -ret) if ret < 0
      self.handle = handle_p.get_pointer(0)
    end

    def close
      return unless open?
      Lib::Rbd.rbd_close(handle)
      self.handle = nil
    end

    def destroy
      close if open?
      ret = Lib::Rbd.rbd_remove(pool.handle, name)
      raise SystemCallError.new("destroy of '#{name}' failed", -ret) if ret < 0
    end

    def write(offset, data)
      ensure_open
      size = data.bytesize
      ret = Lib::Rbd.rbd_write(handle, offset, size, data)
      raise SystemCallError.new("write of #{size} bytes to '#{name}' at #{offset} failed", -ret) if ret < 0
      raise Errno::EIO.new("wrote only #{ret} of #{size} bytes to '#{name}' at #{offset}") if ret < size
    end

    def read(offset, size)
      ensure_open
      data_p = FFI::MemoryPointer.new(:char, size)
      ret = Lib::Rbd.rbd_read(handle, offset, size, data_p)
      raise SystemCallError.new("read of #{size} bytes from '#{name}' at #{offset} failed", -ret) if ret < 0
      data_p.get_bytes(0, ret)
    end

    def stat
      ensure_open
      stat = Lib::Rbd::StatStruct.new
      ret = Lib::Rbd.rbd_stat(handle, stat, stat.size)
      raise SystemCallError.new("stat of '#{name}' failed", -ret) if ret < 0
      Hash[[:size, :obj_size, :num_objs, :order].map{ |k| [k, stat[k]] }].tap do |hash|
        hash[:block_name_prefix] = stat[:block_name_prefix].to_ptr.read_string
      end
    end

    def resize(size)
      ensure_open
      ret = Lib::Rbd.rbd_resize(handle, size)
      raise SystemCallError.new("resize of '#{name}' to #{size} failed", -ret) if ret < 0
    end

    def size
      stat[:size]
    end

    def copy_to(dst_name, dst_pool = nil)
      ensure_open
      case dst_pool
      when String
        dst_pool = cluster.pool(dst_pool)
      when nil
        dst_pool = pool
      end
      dst_pool.ensure_open
      ret = Lib::Rbd.rbd_copy(handle, dst_pool.handle, dst_name)
      raise SystemCallError.new("copy of '#{name}' to '#{dst_pool.name}/#{dst_name}' failed", -ret) if ret < 0
    end

    # helper methods below

    def open?
      !!handle
    end

    def ensure_open
      return if open?
      open
    end
  end
end
