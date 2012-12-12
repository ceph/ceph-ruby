module CephRuby
  class Rbd
    class Image
      attr_accessor :state, :rbd, :name, :image

      def initialize(rbd, name, snapshot = nil)
        raise ArgumentError, "name must be a string" unless name.is_a?(String)
        raise ArgumentError, "snapshot must be a string" if snapshot && !snapshot.is_a?(String)

        image_p = FFI::MemoryPointer.new(:pointer)
        ret = Lib.rbd_open(rbd.pool.ioctx, name, image_p, snapshot)
        raise "could not open rbd image '#{name}': #{ret}" if ret < 0

        self.image = image_p.get_pointer(0)
        self.rbd = rbd
        self.name = name
        self.state = :initialized

        if block_given?
          yield self
          close
        end
      end

      def close
        require_state(:initialized)
        Lib.rbd_close(image)
        self.state = :closed
      end

      def write(offset, data)
        require_state(:initialized)
        raise ArgumentError, "offset must be an integer" unless offset.is_a?(Integer)
        size = data.bytesize
        ret = Lib.rbd_write(image, offset, size, data)
        raise "error writing #{size} bytes to image '#{name}': #{ret}" if ret < 0
        raise "wrote only #{ret} of #{size} bytes to image '#{name}' @ #{offset}" if ret < size
      end

      def read(offset, size)
        require_state(:initialized)
        raise ArgumentError, "offset must be an integer" unless offset.is_a?(Integer)
        raise ArgumentError, "size must be an integer" unless size.is_a?(Integer)
        data_p = FFI::MemoryPointer.new(:char, size)
        ret = Lib.rbd_read(image, offset, size, data_p)
        raise "error reading #{size} bytes from image '#{name}' @ #{offset}: #{ret}" if ret < 0
        data_p.get_bytes(0, ret)
      end

      def stat
        stat = Lib::StatStruct.new
        ret = Lib.rbd_stat(image, stat, stat.size)
        raise "error getting stat of image '#{name}'" if ret < 0
        stat
      end

      def resize(size)
        ret = Lib.rbd_resize(image, size)
        raise "error resizing image '#{name}' to #{size} bytes" if ret < 0
      end

      def size
        stat[:size]
      end

      def copy_to(dst_pool, dst_name)
        require_state(:initialized)
        raise ArgumentError, "dst_pool must be a pool" unless dst_pool.is_a?(Rados::Pool)
        raise ArgumentError, "dst_name must be an string" unless dst_name.is_a?(String)
        ret = Lib.rbd_copy(image, dst_pool.ioctx, dst_name)
        raise "error copying image to '#{dst_pool.name}/#{dst_name}'" if ret < 0
      end

      private

      def require_state(*states)
        return if states.include?(state)
        raise "current state must be one of: #{states*", "}"
      end
    end
  end
end
