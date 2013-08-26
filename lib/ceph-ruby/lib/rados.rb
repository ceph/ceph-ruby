require "ffi"

# see https://github.com/ceph/ceph/blob/v0.48.2argonaut/src/pybind/rados.py

module CephRuby
  module Lib
    module Rados
      extend FFI::Library

      ffi_lib ['rados', 'librados.so.2']

      attach_function 'rados_version', [:pointer, :pointer, :pointer], :void

      attach_function 'rados_create', [:pointer, :string], :int
      attach_function 'rados_connect', [:pointer], :int
      attach_function 'rados_conf_read_file', [:pointer, :string], :int
      attach_function 'rados_shutdown', [:pointer], :void

      attach_function 'rados_pool_lookup', [:pointer, :string], :int

      attach_function 'rados_ioctx_create', [:pointer, :string, :pointer], :int
      attach_function 'rados_ioctx_destroy', [:pointer], :void

      attach_function 'rados_write', [:pointer, :string, :buffer_in, :size_t, :off_t], :int
      attach_function 'rados_read', [:pointer, :string, :buffer_out, :size_t, :off_t], :int
      attach_function 'rados_remove', [:pointer, :string], :int
      attach_function 'rados_trunc', [:pointer, :string, :size_t], :int
      attach_function 'rados_stat', [:pointer, :string, :pointer, :pointer], :int

      def self.version
        major = FFI::MemoryPointer.new(:int)
        minor= FFI::MemoryPointer.new(:int)
        extra = FFI::MemoryPointer.new(:int)
        rados_version(major, minor, extra)
        {
          :major => major.get_int(0),
          :minor => minor.get_int(0),
          :extra => extra.get_int(0),
        }
      end

      def self.version_string
        "#{version[:major]}.#{version[:minor]}.#{version[:extra]}"
      end
    end
  end
end
