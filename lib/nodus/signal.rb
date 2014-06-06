
# -- save/stream a session to a signal / save as a signal
# -- query general information about a signal


module Nodus



  # Typed, decoupled, overlapping input / output streams that correspond to a single actual signal.
  #
  # Responsibilities
  #   - kind of like a 'Model' in many frameworks- a checkpoint if you will for data-flow processing
  #   - db/persistence layer connection
  #   - automatic table creation / modification
  #   - attaching consumers w/ queries
  #   - ...
  class Signal

    # def self.new_from_path
    # * path
    # * live/after-the-fact generator node/node-group
    # * 

#    attr_reader :path_def
#    delegate :path, :table_name, :temp?, to: :path_def
#
#    def initialize(path=nil)
#      @path_def = SignalPath === path ? path : SignalPath.new(path) # nil value means temporary
#
#
#    end

  end

#  module Stores
#    class Base
#
#    end
#
#    class Simple < Base
#      def initialize(path)
#        raise ArgumentError, "Cannot use simple-store for non-temporary or persisted data" unless path.temp?
#        super
#      end
#
#      def 
#    end
#  end

end
