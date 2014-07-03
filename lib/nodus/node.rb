


# - [ ] Input-duals
# - [ ] Output-duals
# - [ ] static composition
# - [ ] dynamic composition

# - [ ] simple generators

module Nodus
  class Node
    def self.input    (name, desc=nil) c_inputs  << OpenStruct.new(name: name, desc: desc) end
    def self.output   (name, desc=nil) c_outputs << OpenStruct.new(name: name, desc: desc) end
    def      input    (name, desc=nil) inputs    << OpenStruct.new(name: name, desc: desc) end
    def      output   (name, desc=nil) outputs   << OpenStruct.new(name: name, desc: desc) end

    def self.c_inputs () @c_inputs  ||= [] end
    def self.c_outputs() @c_outputs ||= [] end
    def      inputs   () @inputs    ||= self.class.c_inputs.dup  end
    def      outputs  () @outputs   ||= self.class.c_outputs.dup end
  end


  # - [ ] sequence state startup for tokens
  # - [ ] automatic (or manual) token creation
  # - [ ] automatic session creation (for now)
  class Generator < Node

  end
end
