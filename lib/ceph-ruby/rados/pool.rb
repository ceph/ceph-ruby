module CephRuby
  class Rados
    class Pool
      attr_accessor :state, :cluster, :name, :ioctx

      def initialize(cluster, name, ioctx)
        self.cluster = cluster
        self.name = name
        self.ioctx = ioctx
        self.state = :initialized

        if block_given?
          yield self
          close
        end
      end

      def close
        require_state(:initialized)
        Lib.rados_ioctx_destroy(ioctx)
        self.state = :closed
      end

      private

      def require_state(*states)
        return if states.include?(state)
        raise "current state must be one of: #{states*", "}"
      end
    end
  end
end
