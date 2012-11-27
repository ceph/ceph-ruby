require "ffi"

# see https://github.com/ceph/ceph/blob/v0.48.2argonaut/src/pybind/rbd.py

module CephRuby
  class Rbd
    module Lib
      extend FFI::Library

      ffi_lib ['rbd', 'librbd.so.1']

      attach_function 'rbd_version', [:pointer, :pointer, :pointer], :void

      attach_function 'rbd_create', [:pointer, :string, :size_t, :pointer], :int
      attach_function 'rbd_remove', [:pointer, :string], :int

      attach_function 'rbd_open', [:pointer, :string, :pointer, :string], :int
      attach_function 'rbd_close', [:pointer], :void

      attach_function 'rbd_write', [:pointer, :off_t, :size_t, :buffer_in], :int
      attach_function 'rbd_read', [:pointer, :off_t, :size_t, :buffer_out], :int
      attach_function 'rbd_stat', [:pointer, :pointer, :size_t], :int
      attach_function 'rbd_resize', [:pointer, :size_t], :int

      class StatStruct < FFI::Struct
        layout :size, :uint64,
          :obj_size, :uint64,
          :num_objs, :uint64,
          :order, :int,
          :block_name_prefix, [:char, 24],
          :parent_pool, :int,
          :parent_name, [:char, 96]
      end
    end
  end
end
