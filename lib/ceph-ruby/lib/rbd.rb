require "ffi"

# see https://github.com/ceph/ceph/blob/v0.48.2argonaut/src/pybind/rbd.py

module CephRuby
  module Lib
    module Rbd
      extend FFI::Library

      ffi_lib ['rbd', 'librbd.so.1']

      attach_function 'rbd_version', [:pointer, :pointer, :pointer], :void

      attach_function 'rbd_create2', [:pointer, :string, :size_t, :uint64, :pointer], :int
      attach_function 'rbd_remove', [:pointer, :string], :int

      attach_function 'rbd_open', [:pointer, :string, :pointer, :string], :int
      attach_function 'rbd_close', [:pointer], :void

      attach_function 'rbd_write', [:pointer, :off_t, :size_t, :buffer_in], :int
      attach_function 'rbd_read', [:pointer, :off_t, :size_t, :buffer_out], :int
      attach_function 'rbd_stat', [:pointer, :pointer, :size_t], :int
      attach_function 'rbd_resize', [:pointer, :size_t], :int

      attach_function 'rbd_copy', [:pointer, :pointer, :string], :int
      attach_function 'rbd_copy_with_progress', [:pointer, :pointer, :string, :pointer, :pointer], :int

      class StatStruct < FFI::Struct
        layout :size, :uint64,
          :obj_size, :uint64,
          :num_objs, :uint64,
          :order, :int,
          :block_name_prefix, [:char, 24],
          :parent_pool, :int, # deprecated
          :parent_name, [:char, 96] # deprecated
      end

      def self.version
        major = FFI::MemoryPointer.new(:int)
        minor= FFI::MemoryPointer.new(:int)
        extra = FFI::MemoryPointer.new(:int)
        rbd_version(major, minor, extra)
        {
          :major => major.get_int(0),
          :minor => minor.get_int(0),
          :extra => extra.get_int(0),
        }
      end
    end
  end
end
