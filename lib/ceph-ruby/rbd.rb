require "ceph-ruby/rbd/lib"
require "ceph-ruby/rbd/image"

module CephRuby
  class Rbd
    attr_accessor :pool

    def self.version
      major = FFI::MemoryPointer.new(:int)
      minor= FFI::MemoryPointer.new(:int)
      extra = FFI::MemoryPointer.new(:int)
      Lib.rbd_version(major, minor, extra)
      {
        :major => major.get_int(0),
        :minor => minor.get_int(0),
        :extra => extra.get_int(0),
      }
    end

    def initialize(pool)
      self.pool = pool
      if block_given?
        yield self
        close
      end
    end

    def close
    end

    def create(name, size, order = 0, &block)
      raise ArgumentError, "name must be a string" unless name.is_a?(String)
      raise ArgumentError, "size must be an integer" unless size.is_a?(Integer)
      raise ArgumentError, "order must be an integer" unless order.is_a?(Integer)

      order_p = FFI::MemoryPointer.new(:int)
      order_p.put_int(0, order)
      ret = Lib.rbd_create(pool.ioctx, name, size, order_p)
      raise "error creating rbd image '#{name}': #{ret}" if ret < 0

      Image.new(self, name, &block) if block
    end

    def open(name, &block)
      Image.new(self, name, &block)
    end

    def destroy(name)
      raise ArgumentError, "name must be a string" unless name.is_a?(String)
      ret = Lib.rbd_remove(pool.ioctx, name)
      raise "error destroying rbd image '#{name}': #{ret}" if ret < 0 && ret != -Errno::ENOENT::Errno
    end
  end
end
