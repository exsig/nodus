module Nodus
  module Actor
    class << self
      def included(klass)
        klass.send :extend, ClassMethods
      end
    end

    module ClassMethods
      def new(*args, &block)
        Nodus::Actor::Proxy.new(self, *args, &block)
      end
      alias_method :spawn, :new
    end

    class Proxy < SimpleDelegator
      # class << self
      #   alias_method :actual_new, :new
      #   private :actual_new
      #   def spawn(klass, *args, &block)
      #     spawned = Rubinius::Channel.new
      #     Thread.new do
      #       actor_proxy = Thread.current[:_actor_proxy_] = actual_new(klass, *args, &block)
      #       spawned << actor_proxy
      #       actor_proxy.run
      #     end
      #     spawned.receive
      #   end
      #   alias_method :new, :spawn
      # end

      def initialize(klass, *args, &block)
        @klass = klass

        @input_channel = Rubinius::Channel.new
        @obj   = @klass.new(*args, &block)

        # TODO: YOU ARE HERE:  setting up a proxy that will act a lot like simpledelegator but won't actually use it.
        # Instead it will put all incoming calls into @obj's new mailbox. It needs to spawn a new thread here (and store
        # it) as well as some channel(s) to communicate with it. Within the new thread the object will be initialized
        # and automatically put into its first state. The actor shuts down when the primary loop exits.

        #@obj.send :initialize, *args, &block
        #super(@obj)
      end

      def but_more
        'muahahaha'
      end

      def __getobj__() @obj; super end
    end

    class Machine

    end

  end
end
